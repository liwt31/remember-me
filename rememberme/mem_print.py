# -*- coding: utf-8 -*-

from print_tree import print_tree as _print_tree

from .rememberme import RememberMe, memory_node, Node

# from https://stackoverflow.com/questions/1094841/reusable-library-to-get-human-readable-version-of-file-size
def sizeof_fmt(num, suffix="B"):
    for unit in ["", "Ki", "Mi", "Gi", "Ti", "Pi", "Ei", "Zi"]:
        if abs(num) < 1024.0:
            return "%3.1f%s%s" % (num, unit, suffix)
        num /= 1024.0
    return "%.1f%s%s" % (num, "Yi", suffix)


class _rme_print_tree(_print_tree):
    def get_children(self, node: Node):
        return node.children or []

    def get_node_str(self, node: Node):
        sz = node.size
        return "%s(%s)" % (type(node.obj).__name__, sizeof_fmt(sz))


def mem_print(*objs):
    inst = RememberMe()
    node = memory_node(inst, 1, *objs)
    _rme_print_tree(node)
