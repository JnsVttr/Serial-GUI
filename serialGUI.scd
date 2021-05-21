// Tangible Signals - Serial Ports GUI
// ===================================


(
// SerialPort.listDevices;
i = (); // all functions
i.midiConnected = false; // true if MIDI is connected
i.midiSendChannel = 1;   // send/ receive channels to be adapted 1 + 0 (WELLE or Emulation)
i.midiReceiveChannel = 0;
i.stringDest = "eq"; // destination for eq or env

// global vars
i.pattern = [0,0,0,0,0,0,0,0];
i.volume = 0.1;  // 425 * 0.296 = 126
i.faderVal = [0,0,0,0,0,0];
i.envelope = [ [ 0, 0.1, 0.3, 1 ], [ 0, 1, 0.4, 0 ] ] ; // atk, dec, sus, rel
i.eq = [[0.0, 0.3, 0.7, 1.0], [0.5, 0.5, 0.5, 0.5]];
i.eqMidi = [ 0.5, 0.25, 0.52, 0.7, 0.5 ];
i.envMidi = [ 0.2, 0.15, 0.35, 0.64 ];
// i.stringInput = 0;
// i.selInst = [1, 1];
// i.selPattern = [1, 1];






////////////////////////////////////////////////////////////
// SEND MIDI FUNCTION
// send/ receive : channel 1 + 2
i.sendMIDI = {|f, message|
	var command = message[\command];
	var content = message[\content];
	("sendMidi - message: " + message).postln;
	if (i.midiConnected, {
		switch(command,
			'sendVolume', {
				i.midiOut.control(i.midiSendChannel, 9, content)
			},
			'sendPattern', {
				content.do({|entry, c|
					var controller = 1 + c;
					var val =  entry;
					i.midiOut.control(i.midiSendChannel, controller, val);
				});
			},
			'sendEq', {
				var newEqMidi = message[1];
				var eqMidi = i.eqMidi;
				for (0, 4, {|c|
					var cc = c+10;  // midi control Eq = cc 10-14
					if (eqMidi[c] != newEqMidi[c], {  // check if eq changed, and only send changed values
						i.midiOut.control(0, cc, newEqMidi[c]*126);
					});

				});
				i.eqMidi = newEqMidi;
			},
			'sendEnv', {
				var newEnvMidi = message[1];
				var envMidi = i.envMidi;
				for (0, 3, {|c|
					var cc = c+16;  // midi control Env = cc 16-20
					if (envMidi[c] != newEnvMidi[c], {  // check if eq changed, and only send changed values
						i.midiOut.control(0, cc, newEnvMidi[c]*126);
					});

				});
				i.envMidi = newEnvMidi;
			}
		)
	})
};



////////////////////////////////////////////////////////////
// SERIAL FUNCTION
// i.serialFunction( ('count': c, 'name': deviceName, 'command': command, 'content': content) );
i.serialFunction = {|f, message|
	var device = message[\name]; // e.g. "pin", "wheel" or "fader"
	var content = message[\content]; // array, e.g. [1,1,1,1,1,1,1,1], [ 182, 0, 0], [ 0, 12, 12, 33, 43, 12]
	var command = message[\command]; // e.g. /pin, /wheel/startPos
	var stringMoved = false;
	var vol, eq, env;
	/*if (device != "fader", {
	("serial function: " + message).postln;
	});*/

	if (device == "pin", {
		content.removeAt(8); // remove last entry, doesn't belong to pattern
		i.sendMIDI( ('command': 'sendPattern', 'content': content) );
	});
	if (device == "wheel", {
		vol = content[0].asInteger;
		vol = (vol * 0.296).asInteger; // asInteger: get rid of decimals
		("serial - " + "wheel vol: " + vol + " command: " + command).postln;
		if ( command == "/wheel", {
			i.sendMIDI( ('command': 'sendVolume', 'content': vol) );
		});
	});
	if (device == "fader", {
		content.removeAt(6);
		// smooth messages
		content.do({|val, c|
			var tolerance = 15;
			var in = val.asInteger.thresh(0).softRound(tolerance, 0, 1);
			var stored = i.faderVal[c].thresh(0).softRound(tolerance, 0, 1);
			if (in != stored, {
				i.faderVal[c] = in;
				stringMoved = true;
			});
		});
		if (stringMoved, {
			// ("serial fader: " + content + "i.faderVal: " + i.faderVal).postln;

		});
	});
};


////////////////////////////////////////////////////////////
// converters
i.convertEnv = {|f, envShort|
	// [0,atk,atk+dec,atk+dec+rel,1]      [0,1,sus,sus,0]
	var envArray = Array2D.new(2,4);
	var atk = envShort[0];
	var dec = envShort[1];
	var sus = envShort[2];
	var rel = envShort[3];
	envArray = [ [0, atk, atk+dec, 1], [0, 1, sus, 0]];
};
i.unConvertEnv = {|f, envLong|
	// [ [ 0, 0.1, 0.6, 1 ], [ 0, 1, 0.4, 0 ] ]
	// [0,atk,atk+dec,atk+dec+rel,1]      [0,1,sus,sus,0]
	var envArray = Array.new(4);
	var atk = envLong[0][1];
	var dec = envLong[0][2]-atk;
	var sus = envLong[1][2];
	var rel = 1-dec-atk;
	envArray = [ atk, dec, sus, rel ];
};

i.convertEq = {|f, settings|
	// [high, highFreq, mid, midFreq, low]
	var high = settings[4];
	var highFreq = settings[3];
	var mid = settings[2];
	var midFreq = settings[1];
	var low = settings[0];
	var eqArray = Array2D.new(2,4);
	eqArray = [[0, midFreq, highFreq, 1], [low, mid, mid, high]];
};
i.unConvertEq = {|f, settings|
	// [[0, midFreq, highFreq, 1], [low, mid, mid, high]]
	var high = settings[1][3];
	var highFreq = settings[0][2];
	var mid = (settings[1][1]+settings[1][2])/2;
	var midFreq = settings[0][1];
	var low = settings[1][0];
	var eqArray = Array.fill(4);
	eqArray = [low, midFreq, mid, highFreq, high];
};



////////////////////////////////////////////////////////////
// SCAN SERIAL PORTS FUNCTION
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
				var byte, str, arr, id, deviceName, command, content, message;
				inf.do{
					if(dev[\port].read==10, {
						str = "";
						while({byte = dev[\port].read; byte !=13 }, {
							str = str++byte.asAscii;
						});
						// STRING
						// split string into array
						arr = str.replace(",", "").split($ );

						// get command and content
						command = arr[0];
						// extract first message and split to device id
						id = arr[0].split($/)[1];
						arr.removeAt(0); // remove first entry (command)
						content = arr;

						switch(id,
							"wheel", {deviceName = "wheel"},
							"pin", {deviceName = "pin"},
							"fader", {deviceName = "fader"},
							{deviceName = nil}
						);
						if (dev[\name] == nil && deviceName != nil, {
							dev[\name] = deviceName;
							dev[\assigned] = true;
							defer {
								if (i.window.isClosed == false, {
									i.displaySerialDevices.value;
								});
							};
						});

						// i.serialFunction([c, deviceName, arr, dev]);
						message = ('count': c, 'name': deviceName, 'command': command, 'content': content);
						i.serialFunction( message );
					});
				};
			}).play;
		});
	});

	defer { i.serialIndex.string = "connected: " + i.serialCount + " (move to assign)"; };
};






// display devices once they are recognized
i.displaySerialDevices = {
	var assigned = 0, displayed = 0;
	i.tangibleDevices.do{|dev|
		if (dev[\assigned], {assigned = assigned + 1});
	};
	// count how many are already displayed
	displayed = i.serialList.string.split($\n).size - 1;
	// if difference, extract new device names and display
	if (assigned > displayed, {
		var serialString = "";
		"update display".postln;
		i.tangibleDevices.do({|dev|
			if (dev[\assigned], {
				serialString = serialString + "> " + dev[\name] + "\n";
			});
		});
		defer { i.serialList.string = serialString };
	});

	defer {
		if (displayed > 2, {
			i.serialIndex.string = "connected: " + i.serialCount;
		});
	}
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
					i.popup.items = ["MIDI:" + i.midiDevices[index].device];
					i.popup.background_(Color.green(0.7));  // only changes the look of displayed item
					MIDIIn.connect;
					i.midiConnected = true;
					// MIDIIn.addFuncTo(\control, ~control);
				});
			});
		};
	};
};


// update string destination
i.updateStringDestination = {|f, string|
	defer {
		if (string == "eq", {
			i.stringDest = "eq";
			i.destEq.states_([["EQ", Color.black, Color.green]]);
			i.destEnv.states_([["ENV", Color.black, Color.white]]);
		});
		if (string == "env", {
			i.stringDest = "env";
			i.destEq.states_([["EQ", Color.black, Color.white]]);
			i.destEnv.states_([["ENV", Color.black, Color.green]]);
		});
	}
};


////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
// make WINDOW
i.makeWindow = {
	// main window
	i.window = Window.new("Tangible Signals - Serial Manager", Rect(10, 1910, 360, 140))
	.front
	.background_(Color.white);

	// interaction:
	i.upperHalfView = CompositeView(i.window, Rect(0,0,530,150)).background_(Color.black);

	// scan serial
	i.scanSerialButton = Button(i.upperHalfView,Rect(10, 16, 100, 30)).states_([["scan devices", Color.black, Color.white]])
	.action_({|b|
		i.scanSerials();
	});
	// serial state
	i.serialIndex = StaticText.new(i.upperHalfView, Rect(15, 35, 290, 60)).stringColor_(Color.white).string_("");
	i.serialList = StaticText.new(i.upperHalfView, Rect(10, 80, 90, 60)).stringColor_(Color.white).string_("");

	// MIDI input choose
	i.popup = PopUpMenu(i.upperHalfView, Rect(140, 16, 190, 30));
	i.popup.stringColor_(Color.black);   // only changes the look of displayed item
	i.popup.font_(Font("Courier", 13));   // only changes the look of displayed item

	// string destination buttons
	StaticText.new(i.upperHalfView, Rect(140, 65, 290, 60)).stringColor_(Color.white).string_("string destination");
	i.destEq = Button(i.upperHalfView,Rect(140, 107, 60, 20)).states_([["EQ", Color.black, Color.white]])
	.action_({|b|
		defer {i.updateStringDestination("eq");}
	});
	i.destEnv = Button(i.upperHalfView,Rect(210, 107, 60, 20)).states_([["ENV", Color.black, Color.white]])
	.action_({|b|
		defer {i.updateStringDestination("env");}
	});
};
i.makeWindow.value;
i.startMIDI.value;
defer {i.updateStringDestination("eq");}


)




/*
// send SERIAL to devices. Re-program Arduino Code (wheel!) to embed same standards.

// pins
i.tangibleDevices[1][\port].putAll("11111010!");
// wheel
i.tangibleDevices[0][\port].putAll("/wheel/startPos, 100, 0, 400, 2000");  // (command, position, revolution, fade in, speed)
// fader
// six numbers, all without comma or space
// add 0 to numbers below 10 (arduino calculation)
// add '!' at the end to define message ending
i.tangibleDevices[2][\port].putAll("007645014763!");

i.tangibleDevices[1][\name]
i.tangibleDevices[1][\port].put(0)
i.tangibleDevices[1][\port].put(49)
i.tangibleDevices[1][\port].put(33)
i.tangibleDevices[1][\port].put(100)

'1'.ascii // 49
'0'.ascii // 48
"!".ascii // 33
'\n'.ascii // 100

*/







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