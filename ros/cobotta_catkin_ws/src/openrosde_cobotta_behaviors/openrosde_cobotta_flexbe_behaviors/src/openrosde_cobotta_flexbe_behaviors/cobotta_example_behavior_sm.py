#!/usr/bin/env python
# -*- coding: utf-8 -*-
###########################################################
#               WARNING: Generated code!                  #
#              **************************                 #
# Manual changes may get lost if file is generated again. #
# Only code inside the [MANUAL] tags will be kept.        #
###########################################################

from flexbe_core import (
    Autonomy,
    Behavior,
    ConcurrencyContainer,
    Logger,
    OperatableStateMachine,
    PriorityContainer,
)
from flexbe_manipulation_states.srdf_state_to_moveit import SrdfStateToMoveit
from flexbe_states.wait_state import WaitState

# Additional imports can be added inside the following tags
# [MANUAL_IMPORT]

# [/MANUAL_IMPORT]


'''
Created on Wed Apr 22 2026
@author: Lotfi El Hafi
'''
class CobottaExampleBehaviorSM(Behavior):
	'''
	Example of a FlexBE behavior that implements a looping arm dance for a COBOTTA robot.
	The arm cycles between the 'home' and 'up' named configurations, with a configurable wait time between moves.
	'''


	def __init__(self):
		super(CobottaExampleBehaviorSM, self).__init__()
		self.name = 'COBOTTA Example Behavior'

		# parameters of this behavior
		self.add_parameter('wait_time', 1.0)

		# references to used behaviors

		# Additional initialization code can be added inside the following tags
		# [MANUAL_INIT]

		# [/MANUAL_INIT]

		# Behavior comments:



	def create(self):
		move_group = 'arm'
		action_topic = '/move_group'
		# x:633 y:190, x:83 y:190
		_state_machine = OperatableStateMachine(outcomes=['finished', 'failed'])

		# Additional creation code can be added inside the following tags
		# [MANUAL_CREATE]

		# [/MANUAL_CREATE]


		with _state_machine:
			# x:225 y:74
			OperatableStateMachine.add('MoveToHome',
										SrdfStateToMoveit(config_name='home', move_group=move_group, action_topic=action_topic, robot_name=''),
										transitions={'reached': 'WaitAtHome', 'planning_failed': 'failed', 'control_failed': 'failed', 'param_error': 'failed'},
										autonomy={'reached': Autonomy.Off, 'planning_failed': Autonomy.Off, 'control_failed': Autonomy.Off, 'param_error': Autonomy.Off},
										remapping={'config_name': 'config_name', 'move_group': 'move_group', 'robot_name': 'robot_name', 'action_topic': 'action_topic', 'joint_values': 'joint_values', 'joint_names': 'joint_names'})

			# x:553 y:74
			OperatableStateMachine.add('WaitAtHome',
										WaitState(wait_time=self.wait_time),
										transitions={'done': 'MoveToUp'},
										autonomy={'done': Autonomy.Off})

			# x:225 y:274
			OperatableStateMachine.add('MoveToUp',
										SrdfStateToMoveit(config_name='up', move_group=move_group, action_topic=action_topic, robot_name=''),
										transitions={'reached': 'WaitAtUp', 'planning_failed': 'failed', 'control_failed': 'failed', 'param_error': 'failed'},
										autonomy={'reached': Autonomy.Off, 'planning_failed': Autonomy.Off, 'control_failed': Autonomy.Off, 'param_error': Autonomy.Off},
										remapping={'config_name': 'config_name', 'move_group': 'move_group', 'robot_name': 'robot_name', 'action_topic': 'action_topic', 'joint_values': 'joint_values', 'joint_names': 'joint_names'})

			# x:553 y:274
			OperatableStateMachine.add('WaitAtUp',
										WaitState(wait_time=self.wait_time),
										transitions={'done': 'MoveToHome'},
										autonomy={'done': Autonomy.Off})


		return _state_machine


	# Private functions can be added inside the following tags
	# [MANUAL_FUNC]

	# [/MANUAL_FUNC]
