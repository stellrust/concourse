// Code generated by mockery v2.8.0. DO NOT EDIT.

package cmocks

import (
	time "time"

	mock "github.com/stretchr/testify/mock"
)

// Component is an autogenerated mock type for the Component type
type Component struct {
	mock.Mock
}

// IntervalElapsed provides a mock function with given fields:
func (_m *Component) IntervalElapsed() bool {
	ret := _m.Called()

	var r0 bool
	if rf, ok := ret.Get(0).(func() bool); ok {
		r0 = rf()
	} else {
		r0 = ret.Get(0).(bool)
	}

	return r0
}

// Name provides a mock function with given fields:
func (_m *Component) Name() string {
	ret := _m.Called()

	var r0 string
	if rf, ok := ret.Get(0).(func() string); ok {
		r0 = rf()
	} else {
		r0 = ret.Get(0).(string)
	}

	return r0
}

// Paused provides a mock function with given fields:
func (_m *Component) Paused() bool {
	ret := _m.Called()

	var r0 bool
	if rf, ok := ret.Get(0).(func() bool); ok {
		r0 = rf()
	} else {
		r0 = ret.Get(0).(bool)
	}

	return r0
}

// Reload provides a mock function with given fields:
func (_m *Component) Reload() (bool, error) {
	ret := _m.Called()

	var r0 bool
	if rf, ok := ret.Get(0).(func() bool); ok {
		r0 = rf()
	} else {
		r0 = ret.Get(0).(bool)
	}

	var r1 error
	if rf, ok := ret.Get(1).(func() error); ok {
		r1 = rf()
	} else {
		r1 = ret.Error(1)
	}

	return r0, r1
}

// UpdateLastRan provides a mock function with given fields: when
func (_m *Component) UpdateLastRan(when time.Time) error {
	ret := _m.Called(when)

	var r0 error
	if rf, ok := ret.Get(0).(func(time.Time) error); ok {
		r0 = rf(when)
	} else {
		r0 = ret.Error(0)
	}

	return r0
}
