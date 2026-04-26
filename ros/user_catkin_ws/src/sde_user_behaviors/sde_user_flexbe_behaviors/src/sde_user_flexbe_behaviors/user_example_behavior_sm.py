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
Created on Sun Apr 26 2026
@author: SDE User
'''
class UserExampleBehaviorSM(Behavior):
	'''
	Minimal user-overlay FlexBE behavior.
	Logs a message and waits.
	Demonstrates that the user workspace builds and is loaded by the FlexBE app.
	'''


	def __init__(self):
		super(UserExampleBehaviorSM, self).__init__()
		self.name = 'User Example Behavior'

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
			OperatableStateMachine.add('LogMessage',
										LogState(text='Hello from the SDE user overlay!', severity=Logger.REPORT_HINT),
										transitions={'done': 'WaitAfterMessage'},
										autonomy={'done': Autonomy.Off})

			# x:553 y:74
			OperatableStateMachine.add('WaitAfterMessage',
										WaitState(wait_time=self.wait_time),
										transitions={'done': 'finished'},
										autonomy={'done': Autonomy.Off})


		return _state_machine


	# Private functions can be added inside the following tags
	# [MANUAL_FUNC]

	# [/MANUAL_FUNC]
