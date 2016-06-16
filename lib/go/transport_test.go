package frugal

import (
	"errors"
	"testing"
	"time"

	"git.apache.org/thrift.git/lib/go/thrift"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// Ensures IsErrTooLarge correctly classifies errors.
func TestIsErrTooLarge(t *testing.T) {
	assert.True(t, IsErrTooLarge(ErrTooLarge))
	assert.True(t, IsErrTooLarge(thrift.PrependError("error", ErrTooLarge)))
	assert.True(t, IsErrTooLarge(thrift.NewTTransportException(REQUEST_TOO_LARGE, "error")))
	assert.True(t, IsErrTooLarge(thrift.NewTTransportException(RESPONSE_TOO_LARGE, "error")))
	assert.False(t, IsErrTooLarge(nil))
	assert.False(t, IsErrTooLarge(errors.New("error")))
	assert.False(t, IsErrTooLarge(thrift.NewTTransportException(thrift.NOT_OPEN, "error")))
	assert.False(t, IsErrTooLarge(thrift.NewTApplicationException(0, "error")))
}

// Ensures SetMonitor starts the FTransportMonitor and setting another monitor
// triggers the previous monitor's clean close. Closing the transport triggers
// a clean close on the active monitor.
func TestFMuxTransportSetMonitor(t *testing.T) {
	mockTTransport := new(mockTTransport)
	mockMonitor := new(mockFTransportMonitor)
	tr := NewFMuxTransport(mockTTransport, 0)
	mockTTransport.On("Open").Return(nil)
	mockTTransport.On("Read", mock.Anything).Return(0, nil)
	mockTTransport.On("Close").Return(nil)
	mockTTransport.On("IsOpen").Return(false)
	mockTTransport.reads = make(chan []byte)
	mockMonitor.On("OnClosedCleanly").Return(nil)

	tr.SetMonitor(mockMonitor)
	assert.Nil(t, tr.Open())
	mockMonitor2 := new(mockFTransportMonitor)
	mockMonitor2.On("OnClosedCleanly").Return(nil)

	// Setting a new monitor should trigger clean close on the previous one.
	tr.SetMonitor(mockMonitor2)
	assert.Nil(t, tr.Close())
	time.Sleep(5 * time.Millisecond)

	mockMonitor.AssertExpectations(t)
	mockMonitor2.AssertExpectations(t)
}

// Ensures SetRegistry panics when the registry is nil.
func TestFMuxTransportSetRegistryNilPanic(t *testing.T) {
	tr := NewFMuxTransport(nil, 0)
	defer func() {
		assert.NotNil(t, recover())
	}()
	tr.SetRegistry(nil)
}

// Ensures SetRegistry does nothing if the registry is already set.
func TestFMuxTransportSetRegistryAlreadySet(t *testing.T) {
	registry := NewFClientRegistry()
	tr := NewFMuxTransport(nil, 0)
	tr.SetRegistry(registry)
	assert.Equal(t, registry, tr.(*fMuxTransport).registry)
	tr.SetRegistry(NewServerRegistry(nil, nil, nil))
	assert.Equal(t, registry, tr.(*fMuxTransport).registry)
}