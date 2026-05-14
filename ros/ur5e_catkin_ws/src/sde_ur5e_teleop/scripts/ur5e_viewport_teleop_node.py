#!/usr/bin/env python

import rospy

from geometry_msgs.msg import Twist
from geometry_msgs.msg import TwistStamped


class TwistAdapter:

    def __init__(self):

        self.latest_twist = Twist()

        self.last_msg_time = rospy.Time.now()

        rospy.Subscriber(
            "/cmd_vel",
            Twist,
            self.cmd_callback
        )

        self.pub = rospy.Publisher(
            "/servo_server/delta_twist_cmds",
            TwistStamped,
            queue_size=10
        )

        self.frame_id = "base_link"

    def cmd_callback(self, msg):

        self.latest_twist = msg
    
        self.last_msg_time = rospy.Time.now()


    def run(self):

        rate = rospy.Rate(100)

        while not rospy.is_shutdown():

            stamped = TwistStamped()

            stamped.header.stamp = rospy.Time.now()

            stamped.header.frame_id = self.frame_id

            dt = rospy.Time.now() - self.last_msg_time

            if dt.to_sec() > 0.2:
                self.latest_twist = Twist()
    
            stamped.twist = self.latest_twist

            self.pub.publish(stamped)

            rate.sleep()



if __name__ == "__main__":

    rospy.init_node("twist_adapter")

    node = TwistAdapter()

    node.run()
