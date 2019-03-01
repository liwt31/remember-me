# -*- coding: utf-8 -*-

import inspect

from print_tree import print_tree as _print_tree

from .rememberme import RememberMe, Node

# from https://stackoverflow.com/questions/1094841/reusable-library-to-get-human-readable-version-of-file-size
def sizeof_fmt(num, suffix="B"):
    for unit in ["", "Ki", "Mi", "Gi", "Ti", "Pi", "Ei", "Zi"]:
        if abs(num) < 1024.0:
            return "%3.1f%s%s" % (num, unit, suffix)
        num /= 1024.0
    return "%.1f%s%s" % (num, "Yi", suffix)


class _rme_print_tree(_print_tree):
    def get_children(self, node: Node):
        return node.children

    def get_node_str(self, node: Node):
        return "%s(%s)" % (type(node.obj).__name__, sizeof_fmt(node.total_size))


def mem_print(*args):
    inst = RememberMe()
    if len(args) == 0:
        frame = inspect.stack()[1].frame
        node = inst.local(frame)
        _rme_print_tree(node)
    else:
        inst = RememberMe()
        node = inst.single(args)
        _rme_print_tree(node)
