# Serial GUI



Serial GUI - a helper for "Tangible Signals" to convert from serial input to MIDI and MIDI to serial messages with SuperCollider.



Detects ESP32 devices in ```/dev/``` based on the namespace ```*SLAB*``` . Connects to serial ports and sends a serial command to each device to request identification (response e.g. "string"). Once identified, each devices is assigned to send/receive serial messages/ MIDI messages. 



<img src="Serial GUI.png" alt="Serial GUI" style="zoom:50%;" />

