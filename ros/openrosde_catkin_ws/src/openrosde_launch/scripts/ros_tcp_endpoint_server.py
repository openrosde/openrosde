#!/usr/bin/env python3

# This script runs the Unity ROS TCP Endpoint with the system commands that remove a registration.
#
# The ROS 1 endpoint '0.7.0' does not implement '__remove_subscriber', '__remove_publisher', '__remove_ros_service', or '__remove_unity_service',
# which the ROS TCP Connector '0.7.0' sends when a Unity client drops its last subscription, publisher, or service on a topic.
# Upstream looks a system command up without a default, so an unknown one raises an 'AttributeError' in the client thread, which closes the connection,
# and the Unity client reconnects about two seconds later, as Coarobo Sightline did whenever it turned a sensor layer off or started an alignment.
# This node adds the four commands to the upstream 'SysCommands', answers any other unknown command with an error sent to Unity instead of dropping the connection,
# then starts the upstream server unchanged.
#
# Usage: rosrun openrosde_launch ros_tcp_endpoint_server.py _tcp_ip:=<ip> _tcp_port:=<port>

import json

import rospy

from ros_tcp_endpoint import TcpServer
from ros_tcp_endpoint.server import SysCommands


def make_remove_command(table_name, label):
    """Returns a system command that unregisters the node of a topic from one of the tables of the server."""

    def remove(self, topic):
        node = getattr(self.tcp_server, table_name).pop(topic, None)
        if node is None:
            return
        self.tcp_server.unregister_node(node)
        self.tcp_server.loginfo("{}({}) OK".format(label, topic))

    return remove


SysCommands.remove_subscriber = make_remove_command("subscribers_table", "RemoveSubscriber")
SysCommands.remove_publisher = make_remove_command("publishers_table", "RemovePublisher")
SysCommands.remove_ros_service = make_remove_command("ros_services_table", "RemoveRosService")
SysCommands.remove_unity_service = make_remove_command("unity_services_table", "RemoveUnityService")


def handle_syscommand(self, topic, data):
    """Runs a system command from Unity, and answers an unknown one with an error instead of closing the connection."""
    name = topic[2:]
    function = None if name.startswith("_") else getattr(self.syscommands, name, None)
    if not callable(function):
        self.logwarn("Unknown system command '{}' from Unity".format(topic))
        self.send_unity_error("Don't understand SysCommand.'{}'".format(topic))
        return
    params = json.loads(data.decode("utf-8"))
    function(**params)


TcpServer.handle_syscommand = handle_syscommand


def main():
    rospy.init_node("unity_endpoint", anonymous=True)
    tcp_server = TcpServer(rospy.get_name())
    tcp_server.start()
    rospy.spin()


if __name__ == "__main__":
    main()
