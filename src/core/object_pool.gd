class_name ObjectPool
extends RefCounted
## Reuses objects instead of creating/freeing them. The factory creates a new
## object when the pool is empty; resetting state is the caller's job.

var _factory: Callable
var _free: Array[Object] = []
var _created: int = 0


func _init(factory: Callable) -> void:
	_factory = factory


func prewarm(count: int) -> void:
	for i in count:
		_free.append(_create())


func acquire() -> Object:
	if _free.is_empty():
		return _create()
	return _free.pop_back()


func release(obj: Object) -> void:
	_free.append(obj)


func free_count() -> int:
	return _free.size()


func created_count() -> int:
	return _created


func _create() -> Object:
	_created += 1
	return _factory.call()
