#!/usr/bin/env python3

import rospy
from controller_manager_msgs.srv import (
    ListControllers,
    ListControllersRequest,
    SwitchController,
    SwitchControllerRequest,
)


class Ur5eSwitchControllerModeNode(object):
    def __init__(self):
        self.switch_service_name = rospy.get_param("~switch_service_name", "/controller_manager/switch_controller")
        self.controllers_to_start = self._parse_controller_list(rospy.get_param("~controllers_to_start", []))
        self.controllers_to_stop = self._parse_controller_list(rospy.get_param("~controllers_to_stop", []))
        self.strictness = rospy.get_param("~strictness", 2)
        self.start_asap = rospy.get_param("~start_asap", False)
        self.timeout = rospy.get_param("~timeout", 5.0)
        self.wait_for_service_timeout = rospy.get_param("~wait_for_service_timeout", 20.0)

        if not self.controllers_to_start and not self.controllers_to_stop:
            rospy.loginfo("No controller switch requested")
            return

        try:
            rospy.wait_for_service(self.switch_service_name, timeout=self.wait_for_service_timeout)
        except rospy.ROSException as error:
            rospy.logwarn("Controller switch service %s not available: %s", self.switch_service_name, error)
            return

        self.controllers_to_start, self.controllers_to_stop = self._filter_available_controllers(
            self.controllers_to_start,
            self.controllers_to_stop,
        )

        if not self.controllers_to_start and not self.controllers_to_stop:
            rospy.loginfo("No controller changes required after filtering unavailable controllers")
            return

        service = rospy.ServiceProxy(self.switch_service_name, SwitchController)
        request = SwitchControllerRequest()
        request.start_controllers = self.controllers_to_start
        request.stop_controllers = self.controllers_to_stop
        request.strictness = self.strictness
        request.start_asap = self.start_asap
        request.timeout = self.timeout

        try:
            response = service(request)
        except rospy.ServiceException as error:
            rospy.logwarn("Failed to switch controllers via %s: %s", self.switch_service_name, error)
            return

        if response.ok:
            rospy.loginfo(
                "Switched controllers. started=%s stopped=%s",
                self.controllers_to_start,
                self.controllers_to_stop,
            )
        else:
            rospy.logwarn(
                "Controller switch was rejected. started=%s stopped=%s",
                self.controllers_to_start,
                self.controllers_to_stop,
            )

    @staticmethod
    def _parse_controller_list(raw_value):
        if isinstance(raw_value, list):
            return [value for value in raw_value if value]
        if not raw_value:
            return []
        return [value.strip() for value in str(raw_value).split(",") if value.strip()]

    def _filter_available_controllers(self, controllers_to_start, controllers_to_stop):
        list_service_name = self._derive_list_service_name(self.switch_service_name)
        try:
            rospy.wait_for_service(list_service_name, timeout=self.wait_for_service_timeout)
            list_service = rospy.ServiceProxy(list_service_name, ListControllers)
            response = list_service(ListControllersRequest())
        except (rospy.ROSException, rospy.ServiceException) as error:
            rospy.logwarn(
                "Failed to query controller states via %s: %s",
                list_service_name,
                error,
            )
            return controllers_to_start, controllers_to_stop

        controller_states = {controller.name: controller.state for controller in response.controller}

        filtered_start = []
        for controller_name in controllers_to_start:
            state = controller_states.get(controller_name)
            if state == "running":
                rospy.loginfo("Controller %s is already running; skipping start request", controller_name)
                continue
            filtered_start.append(controller_name)

        filtered_stop = []
        for controller_name in controllers_to_stop:
            state = controller_states.get(controller_name)
            if state is None:
                rospy.loginfo("Controller %s is not loaded; skipping stop request", controller_name)
                continue
            if state == "stopped":
                rospy.loginfo("Controller %s is already stopped; skipping stop request", controller_name)
                continue
            filtered_stop.append(controller_name)

        return filtered_start, filtered_stop

    @staticmethod
    def _derive_list_service_name(switch_service_name):
        if switch_service_name.endswith("/switch_controller"):
            return switch_service_name[: -len("/switch_controller")] + "/list_controllers"
        if switch_service_name.endswith("switch_controller"):
            return switch_service_name[: -len("switch_controller")] + "list_controllers"
        return "/controller_manager/list_controllers"


def main():
    rospy.init_node("ur5e_controller_manager_switch")
    Ur5eSwitchControllerModeNode()


if __name__ == "__main__":
    main()
