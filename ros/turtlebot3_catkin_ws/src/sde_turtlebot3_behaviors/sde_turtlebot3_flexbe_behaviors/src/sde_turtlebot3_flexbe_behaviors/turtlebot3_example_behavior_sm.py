#!/usr/bin/env python
# -*- coding: utf-8 -*-
###########################################################
#               WARNING: Generated code!                  #
#              **************************                 #
# Manual changes may get lost if file is generated again. #
# Only code inside the [MANUAL] tags will be kept.        #
###########################################################

from flexbe_core import Behavior, Autonomy, OperatableStateMachine, ConcurrencyContainer, PriorityContainer, Logger
from flexbe_navigation_states.move_base_state import MoveBaseState
from flexbe_states.wait_state import WaitState
# Additional imports can be added inside the following tags
# [MANUAL_IMPORT]
from geometry_msgs.msg import Pose2D
# [/MANUAL_IMPORT]


'''
Created on Sun Aug 18 2024
@author: Lotfi El Hafi
'''
class TurtleBot3ExampleBehaviorSM(Behavior):
	'''
	Example of a FlexBE behavior that implements looping navigation for a TurtleBot3 robot.
	The robot loops between two waypoints, with a configurable wait time at each waypoint.
	'''


	def __init__(self):
		super(TurtleBot3ExampleBehaviorSM, self).__init__()
		self.name = 'TurtleBot3 Example Behavior'

		# parameters of this behavior
		self.add_parameter('wait_time', 1.0)

		# references to used behaviors

		# Additional initialization code can be added inside the following tags
		# [MANUAL_INIT]

		# [/MANUAL_INIT]

		# Behavior comments:



	def create(self):
		# x:633 y:190, x:83 y:190
		_state_machine = OperatableStateMachine(outcomes=['finished', 'failed'])
		_state_machine.userdata.waypoint_1 = Pose2D(x=2.0, y=0.5, theta=-3.14)
		_state_machine.userdata.waypoint_2 = Pose2D(x=-2.0, y=-0.5, theta=0.0)

		# Additional creation code can be added inside the following tags
		# [MANUAL_CREATE]

		# [/MANUAL_CREATE]


		with _state_machine:
			# x:225 y:74
			OperatableStateMachine.add('MoveToWaypoint1',
										MoveBaseState(),
										transitions={'arrived': 'WaitAtWaypoint1', 'failed': 'failed'},
										autonomy={'arrived': Autonomy.Off, 'failed': Autonomy.Off},
										remapping={'waypoint': 'waypoint_1'})

			# x:225 y:274
			OperatableStateMachine.add('MoveToWaypoint2',
										MoveBaseState(),
										transitions={'arrived': 'WaitAtWaypoint2', 'failed': 'failed'},
										autonomy={'arrived': Autonomy.Off, 'failed': Autonomy.Off},
										remapping={'waypoint': 'waypoint_2'})

			# x:553 y:74
			OperatableStateMachine.add('WaitAtWaypoint1',
										WaitState(wait_time=self.wait_time),
										transitions={'done': 'MoveToWaypoint2'},
										autonomy={'done': Autonomy.Off})

			# x:553 y:274
			OperatableStateMachine.add('WaitAtWaypoint2',
										WaitState(wait_time=self.wait_time),
										transitions={'done': 'MoveToWaypoint1'},
										autonomy={'done': Autonomy.Off})


		return _state_machine


	# Private functions can be added inside the following tags
	# [MANUAL_FUNC]

	# [/MANUAL_FUNC]
