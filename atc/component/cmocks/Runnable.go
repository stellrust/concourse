// Code generated by mockery v2.8.0. DO NOT EDIT.

package cmocks

import (
	context "context"

	mock "github.com/stretchr/testify/mock"
)

// Runnable is an autogenerated mock type for the Runnable type
type Runnable struct {
	mock.Mock
}

// Run provides a mock function with given fields: _a0
func (_m *Runnable) Run(_a0 context.Context) error {
	ret := _m.Called(_a0)

	var r0 error
	if rf, ok := ret.Get(0).(func(context.Context) error); ok {
		r0 = rf(_a0)
	} else {
		r0 = ret.Error(0)
	}

	return r0
}
