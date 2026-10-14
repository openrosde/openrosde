#!/usr/bin/env python3

"""Relay end effector twist commands to the Fetch native Cartesian twist controller.

The Fetch has a native Cartesian twist controller (robot_controllers/CartesianTwistController).
This node subscribes to a geometry_msgs/TwistStamped end effector velocity command (for example
published by the Coarobo Sightline OpenXR application), clamps it to safe limits, and republishes
it at a fixed rate to the Fetch arm Cartesian twist controller. When commands go stale the relay
publishes zeros so the arm holds its pose instead of drifting (deadman behaviour).

By default the node starts in velocity control so teleoperation is live as soon as it
launches, with no manual controller switch required. A fetch_switch_controllers service
is still provided to disable or re-enable forwarding, and to return the arm to a held
trajectory position.

Ported from the Fetch-era fetch_servoing package (author: Gustavo Garcia) into OpenRoSDE.
"""

import rospy
from rospy import Duration
from geometry_msgs.msg import TwistStamped
from sensor_msgs.msg import JointState
from actionlib import SimpleActionClient
from control_msgs.msg import FollowJointTrajectoryAction, FollowJointTrajectoryGoal
from trajectory_msgs.msg import JointTrajectory, JointTrajectoryPoint
from openrosde_fetch_teleop.srv import FetchSwitchController, FetchSwitchControllerResponse


class FetchCartesianTwistControlNode(object):
    def __init__(self):
        rospy.init_node("fetch_cartesian_twist_control", anonymous=False)

        # Parameters (overridable from the launch file).
        self.input_twist_topic = rospy.get_param("~input_twist_topic", "fetch_ee_cmd_vel")
        self.command_out_topic = rospy.get_param("~command_out_topic", "/arm_controller/cartesian_twist/command")
        # Time between outgoing messages.
        # Fetch needs a steady stream (at least 20 Hz) even when zero, otherwise the arm can fall.
        self.send_period = rospy.get_param("~send_period", 0.050)
        # Safety limits.
        # Keep these small so there is always time to reach the stop button.
        self.max_linear_velocity = rospy.get_param("~max_linear_velocity", 0.05)
        self.max_angular_velocity = rospy.get_param("~max_angular_velocity", 0.10)
        start_in_velocity = rospy.get_param("~start_in_velocity_control", True)

        self.arm_joint_names = [
            "shoulder_pan_joint", "shoulder_lift_joint", "upperarm_roll_joint",
            "elbow_flex_joint", "forearm_roll_joint", "wrist_flex_joint", "wrist_roll_joint",
        ]
        self.current_arm_joint_positions = [0.0] * len(self.arm_joint_names)

        # Start live by default so the user does not need to switch controllers.
        self.active_control = "velocity_control" if start_in_velocity else "position_control"

        self.incoming_cmd_vel = None
        self.incoming_cmd_vel_last_timestamp = None

        self.twist_pub = rospy.Publisher(self.command_out_topic, TwistStamped, queue_size=5)
        rospy.Subscriber(self.input_twist_topic, TwistStamped, self.incoming_cmd_vel_callback)
        rospy.Subscriber("/joint_states", JointState, self.joint_state_callback)
        rospy.Service("fetch_switch_controllers", FetchSwitchController, self.switch_controllers_callback)

        self.timer = rospy.Timer(Duration(self.send_period), self.outgoing_cmd_vel_callback)

        rospy.loginfo("fetch_cartesian_twist_control ready. Input: %s -> output: %s. Active control: %s.",
                      self.input_twist_topic, self.command_out_topic, self.active_control)

    @staticmethod
    def _clamp(value, limit):
        return max(-limit, min(limit, value))

    def incoming_cmd_vel_callback(self, msg):
        if self.active_control != "velocity_control":
            return
        msg.twist.linear.x = self._clamp(msg.twist.linear.x, self.max_linear_velocity)
        msg.twist.linear.y = self._clamp(msg.twist.linear.y, self.max_linear_velocity)
        msg.twist.linear.z = self._clamp(msg.twist.linear.z, self.max_linear_velocity)
        msg.twist.angular.x = self._clamp(msg.twist.angular.x, self.max_angular_velocity)
        msg.twist.angular.y = self._clamp(msg.twist.angular.y, self.max_angular_velocity)
        msg.twist.angular.z = self._clamp(msg.twist.angular.z, self.max_angular_velocity)
        self.incoming_cmd_vel = msg
        self.incoming_cmd_vel_last_timestamp = rospy.Time.now()

    def outgoing_cmd_vel_callback(self, event):
        if self.active_control != "velocity_control":
            return
        if self.incoming_cmd_vel is None or self.incoming_cmd_vel_last_timestamp is None:
            return

        velocity = TwistStamped()
        velocity.header.stamp = rospy.Time.now()
        velocity.header.frame_id = self.incoming_cmd_vel.header.frame_id
        if (rospy.Time.now() - self.incoming_cmd_vel_last_timestamp) <= Duration(self.send_period):
            velocity.twist = self.incoming_cmd_vel.twist
        # Otherwise leave the twist at zero (deadman) so the arm holds its pose.
        self.twist_pub.publish(velocity)

    def joint_state_callback(self, msg):
        for joint in msg.name:
            if joint in self.arm_joint_names:
                idx = self.arm_joint_names.index(joint)
                self.current_arm_joint_positions[idx] = msg.position[msg.name.index(joint)]

    def hold_current_arm_position(self):
        rospy.loginfo("Holding current arm position via arm_controller/follow_joint_trajectory...")
        arm_client = SimpleActionClient("arm_controller/follow_joint_trajectory", FollowJointTrajectoryAction)
        arm_client.wait_for_server()

        target = list(self.current_arm_joint_positions)
        if all(x == 0.0 for x in target):
            rospy.logerr("Arm joint positions are all zero (are /joint_states being received?). Not switching.")
            return False

        trajectory = JointTrajectory()
        trajectory.joint_names = self.arm_joint_names
        point = JointTrajectoryPoint()
        point.positions = target
        point.velocities = [0.0] * len(target)
        point.accelerations = [0.0] * len(target)
        point.time_from_start = rospy.Duration(1.0)
        trajectory.points.append(point)

        goal = FollowJointTrajectoryGoal()
        goal.trajectory = trajectory
        goal.goal_time_tolerance = rospy.Duration(0.0)
        arm_client.send_goal(goal)
        arm_client.wait_for_result(rospy.Duration(6.0))
        rospy.loginfo("...arm position held.")
        return True

    def switch_controllers_callback(self, request):
        response = FetchSwitchControllerResponse()
        response.success = False

        name = request.fetch_controller_name
        if name == "position_control":
            if self.active_control == "velocity_control":
                if self.hold_current_arm_position():
                    self.active_control = "position_control"
                    response.success = True
                    rospy.logwarn("Active controller is now position control.")
                else:
                    rospy.logerr("Could not switch back to position control.")
            else:
                rospy.logwarn("Active controller is already position control.")
        elif name == "velocity_control":
            if self.active_control == "position_control":
                self.active_control = "velocity_control"
                response.success = True
                rospy.logwarn("Active controller is now velocity control.")
            else:
                rospy.logwarn("Active controller is already velocity control.")
        else:
            rospy.logerr("Unknown controller name: %s", name)

        return response


if __name__ == "__main__":
    try:
        FetchCartesianTwistControlNode()
        rospy.spin()
    except rospy.ROSInterruptException:
        pass
