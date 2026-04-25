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
from flexbe_states.log_state import LogState
from flexbe_states.wait_state import WaitState

# Additional imports can be added inside the following tags
# [MANUAL_IMPORT]

# [/MANUAL_IMPORT]


'''
Created on Sat Apr 25 2026
@author: Lotfi El Hafi
'''
class HsrExampleBehaviorSM(Behavior):
	'''
	Example of a FlexBE behavior for the Toyota HSR (Human Support Robot).
	The behavior loops between two log messages with a configurable wait time, providing a minimal demonstration that the FlexBE engine is wired in to the HSR catkin workspace.
	Robot motion is intentionally not commanded because the open-source 'hsr-project' GitHub repositories do not include a ROS Noetic navigation stack or MoveIt configuration.
	'''


	def __init__(self):
		super(HsrExampleBehaviorSM, self).__init__()
		self.name = 'Hsr Example Behavior'

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

		# Additional creation code can be added inside the following tags
		# [MANUAL_CREATE]

		# [/MANUAL_CREATE]


		with _state_machine:
			# x:225 y:74
			OperatableStateMachine.add('LogPosition1',
										LogState(text='HSR at position 1', severity=Logger.REPORT_HINT),
										transitions={'done': 'WaitAtPosition1'},
										autonomy={'done': Autonomy.Off})

			# x:553 y:74
			OperatableStateMachine.add('WaitAtPosition1',
										WaitState(wait_time=self.wait_time),
										transitions={'done': 'LogPosition2'},
										autonomy={'done': Autonomy.Off})

			# x:225 y:274
			OperatableStateMachine.add('LogPosition2',
										LogState(text='HSR at position 2', severity=Logger.REPORT_HINT),
										transitions={'done': 'WaitAtPosition2'},
										autonomy={'done': Autonomy.Off})

			# x:553 y:274
			OperatableStateMachine.add('WaitAtPosition2',
										WaitState(wait_time=self.wait_time),
										transitions={'done': 'LogPosition1'},
										autonomy={'done': Autonomy.Off})


		return _state_machine


	# Private functions can be added inside the following tags
	# [MANUAL_FUNC]

	# [/MANUAL_FUNC]
