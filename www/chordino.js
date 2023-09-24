class Chordino extends EventTarget {
  constructor() {
    super()
    this.service = "Chordino";
  }

  emit(event, data) {
    this.dispatchEvent(new CustomEvent(event, { detail: data }));
  }

  on(event, callback) {
    this.addEventListener(event, e => callback(e.detail));
  }

  removeAllListeners() {
    this.removeEventListener('detection')
    this.removeEventListener('error')
    this.removeEventListener('stop')
  }

  start(sampleRate, bufferSize) {
    const args = [sampleRate, bufferSize];
    cordova.exec(
      (data) => {
        this.emit('detection', data)
      },
      (error) => {
        this.emit('error', error)
      },
      this.service,
      "start",
      args
    );
  }

  stop() {
    cordova.exec(
      (data) => {
        this.emit('stop', data)
      },
      (error) => {
        this.emit('error', error)
      },
      this.service,
      "stop",
      []
    );
  }
}

module.exports = new Chordino()
