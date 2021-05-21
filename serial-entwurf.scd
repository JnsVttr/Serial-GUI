// Tangible Signals - Serial Ports
// ===============================

// devices show as /dev/tty.SLAB_USBtoUART + integer

/*
Check device:
"/dev/tty.SLAB_USBtoUART".split($/)[2];
"/dev/tty.SLAB_USBtoUART".split($/)[2].split($.)[0] == "tty";
Check the name:
"/dev/tty.SLAB_USBtoUART".split($.);
"/dev/tty.SLAB_USBtoUART".split($.)[1];
"/dev/tty.SLAB_USBtoUART".split($.)[1].beginsWith("SLAB");

*/

(
SerialPort.listDevices;
i = (); // all functions

i.allSerialDevices = SerialPort.devices;
i.tangibleDevices = Array.fill(3, nil);
i.serialCount = 0;
i.allSerialDevices.do({|dev|
	// check if tty
	if (dev.split($/)[2].split($.)[0] == "tty", {
		// check namespace
		if (dev.split($.)[1].beginsWith("SLAB"), {
			dev.postln;
			// i.tangibleDevices[i.serialCount] = [dev, "name", "port", "routine"];
			i.tangibleDevices[i.serialCount] = ('serial': dev, 'name': nil, 'port': nil, 'routine': nil, 'assigned': false);  // object instead of array
			i.serialCount = i.serialCount + 1;
		});
	});
});



i.tangibleDevices.do({|dev, c|
	if (dev != nil, {
		"Tangible Devices: ".postln;
		dev.postln;
		dev[\port] = SerialPort(
			dev[\serial],
			baudrate: 115200,
			crtscts: true);
		dev[\port].doneAction = { (dev[\serial] + " - serial port got closed").postln; };

		dev[\routine] = Routine({
			var byte, str, arr, id, deviceName;
			inf.do{
				if(dev[\port].read==10, {
					str = "";
					while({byte = dev[\port].read; byte !=13 }, {
						str = str++byte.asAscii;
					});
					// STRING
					// split string into array
					arr = str.replace(",", "").split($ );
					// extract first message and split to device id
					id = arr[0].split($/)[1];

					switch(id,
						"wheel", {deviceName = "wheel"},
						"pin", {deviceName = "pin"},
						"fader", {deviceName = "fader"},
						{deviceName = ""}
					);
					dev[\name] = deviceName;
					dev[\assigned] = true;

					/*("c: " + c).postln;
					("id: " + id).postln;
					("arr: " + arr).postln;
					("check: " + dev[0] + arr).postln;
					("deviceName: " + deviceName).postln;
					("c: " + c).postln;
					("dev: " + c).postln;*/

					i.serialFunction([c, deviceName, arr, dev]);
				});
			};
		}).play;
	});
});


i.serialFunction = {|f, message| if (message[1]!="fader", {
	("serial function: " + message).postln;
	// i.tangibleDevices.do({|dev| if (dev[\assigned], {dev.postln})});
}) };

)




