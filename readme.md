# Remember Me
[![Build Status](https://travis-ci.org/liwt31/remember-me.svg?branch=master)](https://travis-ci.org/liwt31/remember-me)

Rememberme is a handy tool for memory problems in Python. It computes the total memory usage of any
Python objects.

## How to use
`sys.getsizeof` is almost confusing in Python:
```python
import sys
a = [1, 2, 3]
b = [a, a, a]
print(sys.getsizeof(a) == sys.getsizeof(b))  # Can you believe the result is `True~?
```
While `rememberme` gives you a clear idea how large an object is.
```python
from rememberme import memory
a = [1, 2, 3]
b = [a, a, a]
print(memory(a))  # 172 bytes!
print(memory(b))  # 260 bytes!
```

## More features
Check out memory usage in the current frame:
```python
from rememberme import local_memory
def foo():
    a = [1, 2, 3]
    b = [a, a, a]
    return local_memory()
print(foo())  # 260 bytes! Note `a` is included in `b`.
```
Check out top memory consumers:
```python
from rememberme import top
def foo():
    a = [1, 2, 3]
    b = [a, a, a]
    return top()  # with no args, check current frame
print(foo()[0])  # `b` and it's memory usage
print(foo()[1])  # `a` and it's memory usage
```
Even pretty print the result!
```python
from rememberme import mem_print
def foo():
    a = [1, 2, 3]
    b = [a, a, a]
    mem_print(b)
foo()
```
Output:
```
                           ┌int (28.0B)
             ┌list (172.0B)┼int (28.0B)
             │             └int (28.0B)
             │             ┌int (28.0B)
list (260.0B)┼list (172.0B)┼int (28.0B)
             │             └int (28.0B)
             │             ┌int (28.0B)
             └list (172.0B)┼int (28.0B)
                           └int (28.0B)
```

## Known issues and limitations
* For better performance, the global dict, as well as modules, are not included in 
the memory usage of any objects.
* We essentially relies on [`tp_traverse`](https://docs.python.org/3/c-api/typeobj.html#c.PyTypeObject.tp_traverse) 
to traverse the object graph. For C extensions, memory usage might be underestimated under
various circumstances. For example, memory usage of **subclasses** of `numpy.ndarray` is
not detected properly.