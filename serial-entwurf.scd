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
// SerialPort.listDevices;
i = (); // all functions

i.scanSerials = {
	i.allSerialDevices = SerialPort.devices;
	i.tangibleDevices = Array.fill(3, nil);
	i.serialCount = 0;
	i.allSerialDevices.do({|dev|
		// check if tty
		if (dev.split($/)[2].split($.)[0] == "tty", {
			// check namespace
			if (dev.split($.)[1].beginsWith("SLAB"), {
				// dev.postln;
				// i.tangibleDevices[i.serialCount] = [dev, "name", "port", "routine"];
				i.tangibleDevices[i.serialCount] = ('serial': dev, 'name': nil, 'port': nil, 'routine': nil, 'assigned': false);  // object instead of array
				i.serialCount = i.serialCount + 1;
			});
		});
	});

	i.tangibleDevices.do({|dev, c|
		if (dev != nil, {
			"Tangible Devices - set serial port for : ".post;
			dev[\serial].postln;


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
							{deviceName = nil}
						);
						dev[\name] = deviceName;
						if (dev[\name] != nil, {dev[\assigned] = true;});

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


	i.serialIndex.string = "connected: " + i.serialCount;
};



////////////////////////////////////////////////////////////
// START MIDI function
i.startMIDI = {
	MIDIClient.init;

	defer{
		i.midiPortsNum = MIDIClient.myoutports;
		i.midiDevices = Array.fill(i.midiPortsNum, nil);
		// i.popup.items.clear;
		i.popArr = Array.fill((i.midiPortsNum + 1), 1);
		i.popArr[0] = "connect to MIDI";
		MIDIClient.destinations.do({|d, c|
			c.post; d.device.post; d.name.post; d.uid.postln;
			i.midiDevices[c] = d;
			i.popArr[c+1] = d.device;
		});
		i.midiDevices.postln;
		i.popup.items = i.popArr;
		i.popup.action = { |menu|
			var index = menu.value - 1;
			if (index>=0, {
				[index, menu.value, menu.item].postln;
				if (i.midiOut == nil, {
					i.midiOut = MIDIOut.newByName(i.midiDevices[index].device,i.midiDevices[index].name);
					i.midiOut.noteOn(16, 60, 60);
					i.popup.items = ["MIDI:" + i.midiDevices[index].device];
					i.popup.background_(Color.green(0.7));  // only changes the look of displayed item
					MIDIIn.connect;
					MIDIIn.addFuncTo(\control, ~control);
				});
			});
		};
	};
};



////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
// make WINDOW
i.makeWindow = {
	// main window
	i.window = Window.new("Tangible Signals - Serial Manager", Rect(10, 1910, 530, 200))
	.front
	.background_(Color.white);

	// interaction:
	i.upperHalfView = CompositeView(i.window, Rect(0,0,530,60)).background_(Color.black);
	i.interactionRow = HLayoutView(i.window, Rect(0,90,530,60)).background_(Color.black);

	// scan serial
	i.scanSerialButton = Button(i.upperHalfView,Rect(10, 16, 100, 30)).states_([["Scan serial", Color.black, Color.white]])
	.action_({|b|
		i.scanSerials();
	});
	// serial state
	i.serialIndex = StaticText.new(i.upperHalfView, Rect(120, 0, 90, 60)).stringColor_(Color.white).string_("");

	// MIDI input choose
	i.popup = PopUpMenu(i.upperHalfView, Rect(240, 16, 190, 30));
	i.popup.stringColor_(Color.black);   // only changes the look of displayed item
	i.popup.font_(Font("Courier", 13));   // only changes the look of displayed item

};
i.makeWindow.value;
i.startMIDI.value;
)
