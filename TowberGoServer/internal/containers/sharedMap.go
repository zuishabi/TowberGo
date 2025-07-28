package containers

import "sync"

type SharedIDMap[T any] struct {
	l sync.RWMutex
	m map[uint32]T
}

func NewSharedIDMap[T any]() *SharedIDMap[T] {
	return &SharedIDMap[T]{
		m: make(map[uint32]T),
	}
}

func (s *SharedIDMap[T]) Set(id uint32, obj T) {
	s.l.Lock()
	defer s.l.Unlock()
	s.m[id] = obj
}

func (s *SharedIDMap[T]) Get(id uint32) (T, bool) {
	s.l.RLock()
	defer s.l.RUnlock()
	obj, found := s.m[id]
	return obj, found
}

func (s *SharedIDMap[T]) Remove(id uint32) {
	s.l.Lock()
	defer s.l.Unlock()
	delete(s.m, id)
}

func (s *SharedIDMap[T]) Len() int {
	s.l.RLock()
	defer s.l.RUnlock()
	return len(s.m)
}

func (s *SharedIDMap[T]) ForEach(callback func(uint32, T)) {
	s.l.RLock()
	localCopy := make(map[uint32]T, len(s.m))
	for id, obj := range s.m {
		localCopy[id] = obj
	}
	s.l.RUnlock()
	for id, obj := range localCopy {
		callback(id, obj)
	}
}
