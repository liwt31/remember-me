# -*- coding: utf-8 -*-

from sys import getsizeof

import pytest

from rememberme import memory


def test_numpy():
    try:
        import numpy as np
    except ImportError:
        pytest.skip("numpy is not installed")
        return  # make linter happy
    a = np.random.rand(1000)
    assert memory(a) == getsizeof(a)
    b = a.reshape(-1, 1)
    assert memory(b) == memory(a) + getsizeof(b)
