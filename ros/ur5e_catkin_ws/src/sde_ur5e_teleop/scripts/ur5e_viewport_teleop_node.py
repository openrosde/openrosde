#!/usr/bin/env python

import rospy

from geometry_msgs.msg import Twist
from geometry_msgs.msg import TwistStamped

class TwistAdapter:

   def __init__(self):

       self.latest_twist = Twist()
       self.smoothed_twist = Twist()

       self.last_msg_time = rospy.Time.now()

       # Exponential moving average smoothing factor (0 < alpha <= 1).
       # Lower values produce smoother motion; higher values respond faster.
       self.alpha = rospy.get_param("~smoothing_alpha", 0.1)

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

   def _ema(self, current, target):

       return self.alpha * target + (1.0 - self.alpha) * current

   def run(self):

       rate = rospy.Rate(100)

       while not rospy.is_shutdown():

           dt = rospy.Time.now() - self.last_msg_time

           if dt.to_sec() > 0.2:
               target = Twist()
           else:
               target = self.latest_twist

           # Smooth each component independently with EMA.
           self.smoothed_twist.linear.x = self._ema(self.smoothed_twist.linear.x, target.linear.x)
           self.smoothed_twist.linear.y = self._ema(self.smoothed_twist.linear.y, target.linear.y)
           self.smoothed_twist.linear.z = self._ema(self.smoothed_twist.linear.z, target.linear.z)
           self.smoothed_twist.angular.x = self._ema(self.smoothed_twist.angular.x, target.angular.x)
           self.smoothed_twist.angular.y = self._ema(self.smoothed_twist.angular.y, target.angular.y)
           self.smoothed_twist.angular.z = self._ema(self.smoothed_twist.angular.z, target.angular.z)

           stamped = TwistStamped()

           stamped.header.stamp = rospy.Time.now()

           stamped.header.frame_id = self.frame_id

           stamped.twist = self.smoothed_twist

           self.pub.publish(stamped)

           rate.sleep()

if __name__ == "__main__":

   rospy.init_node("twist_adapter")

   node = TwistAdapter()

   node.run()