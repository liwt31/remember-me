# Remember Me
Rememberme is a simple solution for memory problems in Python. It computes the total memory usage of any
Python objects.

## How to use
`sys.getsizeof` is almost confusing in Python:
```python
import sys
a = [1, 2, 3]
b = [a, a, a]
print(sys.getsizeof(a) == sys.getsizeof(b)) # True!
```
While `rememberme` gives you a clear idea how large an object is.
```python
from rememberme import memory
a = [1, 2, 3]
b = [a, a, a]
print(memory(a)) # 172 bytes!
print(memory(b)) # 260 bytes!
```

## More features
Check out memory usage in current frame:
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
    return top() # with no args, check current frame
print(foo()[0]) # `b` and it's memory usage
print(foo()[1]) # `a` and it's memory usage
```
Even pretty print the result!
```python
from rememberme import pprint_obj
def foo():
    a = [1, 2, 3]
    b = [a, a, a]
    pprint_obj(b)
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