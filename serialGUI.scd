// Tangible Signals - Serial Ports GUI
// ===================================

/*
Troubles: feedback loop - midi to device, device updates serial, serial sends to midi
> for wheel (startposition message could help?)
> no problems with pattern pin
> true for envelope
*/

// Welle website sends MIDI at: 2 (1-16), receives MIDI at: 1 (1-16)
// Emulation. sends MIDI at: 0 (0-15), receives MIDI at 1 (0-15)
// SerialGUI: sends MIDI at: 1 (0-15), receives MIDI at 0 (0-15)



(
// SerialPort.listDevices;
i = (); // all functions
i.midiConnected = false; // true if MIDI is connected
// send-receive channels to be adapted: send to WELLE (1) receive (0); send to Emulation (0), receive (1)
i.midiSendChannel = 0;
i.midiReceiveChannel = 1;
i.stringDest = "eq"; // destination for eq or env

// global vars
i.pattern = [0,0,0,0,0,0,0,0];
i.volume = 0.1;  // 425 * 0.296 = 126
i.faderVal = [0,0,0,0,0,0];
// store String params
i.midiEnv = [ 0.5, 0.25, 0.52, 0.7];
i.midiEq  = [ 0.2, 0.15, 0.35, 0.64, 0.5 ];
i.faderEnv = [0, 90, 30, 0, 30, 30];
i.faderEq = [50, 50, 50, 50, 50, 100];
// store incoming midi pattern
i.midiPattern = [0,0,0,0,0,0,0,0];

// i.envelope = [ [ 0, 0.1, 0.3, 1 ], [ 0, 1, 0.4, 0 ] ] ; // atk, dec, sus, rel
// i.eq = [[0.0, 0.3, 0.7, 1.0], [0.5, 0.5, 0.5, 0.5]];

// i.stringInput = 0;
// i.selInst = [1, 1];
// i.selPattern = [1, 1];







////////////////////////////////////////////////////////////
// SEND SERIAL FUNCTION
// i.sendSerial( ('device': "fader", 'content': [0,10,10,10,30]) );
i.sendSerial = {|f, message|
	var device = message[\device];
	var command = message[\command];
	var content = message[\content];
	// ("send to Serial ...").postln;
	switch(device,
		"fader", {
			var serialString = "", port;
			content.do({|e|
				if (e < 10, {
					serialString = serialString + "0" + e.asString;
				}, {
					serialString = serialString + e.asString;
				});
			});
			serialString = serialString + "!";
			serialString = serialString.replace(" ", "");
			("send to Serial Fader: " + serialString).postln;
			i.tangibleDevices.do({|e, c|
				if (e[\name]=="fader" && e[\assigned]==true, {
					port = i.tangibleDevices[c][\port];
					port.putAll(serialString);
			})});

		},
		"wheel", {
			var serialString = "/wheel/startPos, ", port;
			serialString = serialString + (content * 3.37).asInteger.asString + ", 0, 400, 2000";
			("send to serial wheel: " + serialString).postln;
			i.tangibleDevices.do({|e, c|
				if (e[\name]=="wheel" && e[\assigned]==true, {
					port = i.tangibleDevices[c][\port];
					port.putAll(serialString);
			})});
			// i.tangibleDevices[0][\port].putAll("/wheel/startPos, 100, 0, 400, 2000");  // (command, position, revolution, fade in, speed)
		},
		"pin", {
			var serialString = "", port;
			content.do({|e|
				serialString = serialString + e.asString;
			});
			serialString = serialString + "!";
			serialString = serialString.replace(" ", "");
			// ("serialString: " + serialString).postln;
			i.tangibleDevices.do({|e, c|
				if (e[\name]=="pin" && e[\assigned]==true, {
					// ["serialString: ", serialString].postln;
					i.tangibleDevices[c][\port].putAll(serialString);
					// i.tangibleDevices[c][\port].putAll("10011010!");
				});
			});
		}
	);
};




////////////////////////////////////////////////////////////
// MIDI INPUT function, chan 0-15
~midiInFunction = { |src, chan, num, val|
	//['MIDIIn', chan, num, val].postln;
	if (chan==i.midiReceiveChannel, {
		// ['> MIDIIn > control', chan,num,val].postln;
		if (num==9, {
			['MIDIIn volume', num, val].postln;
			i.sendSerial( ('device': "wheel", 'content': val) );
		});
		if ((num>=1) && (num<=8), {
			var index = num-1;
			i.midiPattern[index] = val;
			//i.sendSerial( ('device': "pin", 'content': i.midiPattern) );
			if (index == 7, {
				['MIDIIn pattern', i.midiPattern].postln;
				i.sendSerial( ('device': "pin", 'content': i.midiPattern) );
			});
		});
		/*if ((num>=10) && (num<=14), {
			var index = num-10;
			['MIDIIn eq', num, val].postln;
			i.eqMidi[index] = val/100;
			['MIDIIn i.eqMidi', i.eqMidi].postln;
			i.eq = i.convertEq(i.eqMidi);
			defer { i.updateWindow() };
		});
		if ((num>=16) && (num<=19), {
			var index = num-16;
			['MIDIIn env', num, val].postln;
			i.envMidi[index] = val/126;
			['MIDIIn i.envMidi', i.envMidi].postln;
			i.envelope = i.convertEnv(i.envMidi);
			defer { i.updateWindow() };
		});*/
	})
};






////////////////////////////////////////////////////////////
// SEND MIDI FUNCTION
// send/ receive : channel 1 + 2
i.sendMIDI = {|f, message|
	var command = message[\command];
	var content = message[\content];
	//("sendMidi - message: " + message).postln;
	if (i.midiConnected, {
		switch(command,
			'sendVolume', {
				i.midiOut.control(i.midiSendChannel, 9, content)
			},
			'sendPattern', {
				content.do({|entry, c|
					var cc = 1 + c;
					var val =  entry;
					i.midiOut.control(i.midiSendChannel, cc, val);
				});
			},
			'sendEq', {
				var newEq = content;
				for (0, 4, {|c|
					var cc = c+10;  // midi control Eq = cc 10-14
					i.midiOut.control(i.midiSendChannel, cc, newEq[c]);
				});

			},
			'sendEnv', {
				var newEnv = content;
				for (0, 3, {|c|
					var cc = c+16;  // midi control Env = cc 16-19
					i.midiOut.control(i.midiSendChannel, cc, newEnv[c]);
				});
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

	("from serial port function: " + message).postln;
	/*if (device != "fader", {
	("serial function: " + message).postln;
	});*/

	if (device == "pin", {
		content.removeAt(8); // remove last entry, doesn't belong to pattern
		i.sendMIDI( ('command': 'sendPattern', 'content': content) );
		// update i.midiPattern
		8.do({|c|
			i.midiPattern[c] = content[c];
		});

	});
	if (device == "wheel", {
		vol = content[0].asInteger;
		vol = (vol * 0.296).asInteger; // asInteger: get rid of decimals
		//("serial in:  " + "wheel vol: " + vol + " command: " + command).postln;
		if ( command == "/wheel", {
			i.sendMIDI( ('command': 'sendVolume', 'content': vol) );
		});
	});
	if (device == "fader", {
		if (content.size > 6, {content.removeAt(6)});
		if (content.size == 6, {
			// smooth messages
			content.do({|val, c|
				var tolerance = 15;
				var in = val.asInteger.softRound(tolerance, 0, 1);
				var stored = i.faderVal[c].softRound(tolerance, 0, 1);
				if (in != stored, {
					i.faderVal[c] = in;
					stringMoved = true;
				});
			});
			if (stringMoved, {
				var newEq, newEnv;
				if (i.stringDest == "eq", {
					newEq = i.unConvertEq(content);
					i.sendMIDI( ('command': 'sendEq', 'content': newEq) );
					content.do({|e, c| i.faderEq[c] = e});
					newEq.do({|e, c| i.midiEq[c] = e});
				});
				if (i.stringDest == "env", {
					newEnv = i.unConvertEnv(content);
					// ("serial send Env to MIDI: " + newEnv).postln;
					i.sendMIDI( ('command': 'sendEnv', 'content': newEnv) );
					content.do({|e, c| i.faderEnv[c] = e});
					newEnv.do({|e, c| i.midiEnv[c] = e});
				});
				//("serial fader: " + content + "newEq: " + newEq).postln;
			});
		});
	});
};


////////////////////////////////////////////////////////////
// converters
/*i.convertEnv = {|f, envShort|
// [0,atk,atk+dec,atk+dec+rel,1]      [0,1,sus,sus,0]
var envArray = Array2D.new(2,4);
var atk = envShort[0];
var dec = envShort[1];
var sus = envShort[2];
var rel = envShort[3];
envArray = [ [0, atk, atk+dec, 1], [0, 1, sus, 0]];
};
*/
i.mapAttack = ControlSpec(5, 50, \lin);
i.mapDecay = ControlSpec(20, 60, \lin);
i.unConvertEnv = {|f, fader|
	// device: [ 1, 2, 3, 4, horizontal1, horizontal2 ]
	// Emulation only: [ [ 0, 0.1, 0.6, 1 ], [ 0, 1, 0.4, 0 ] ] -> [0,atk,atk+dec,atk+dec+rel,1]      [0,1,sus,sus,0]
	// SerialGUI: [horizontal1, horizontal2-horizontal1, 3, 4]
	// .. 1 = 0, 2 = volume. (Volume is tricky, corresponds to Volume wheel. How to embed?)
	var envArray = Array.new(4);
	var atk = i.mapAttack.map(fader[4]/100).asInteger;
	var dec = i.mapDecay.map(fader[5]/100).asInteger - atk;
	var sus = fader[2];
	var rel = fader[3];
	envArray = [ atk, dec, sus, rel ]; // as * 126 [0, 0.1, 0.4, 0.1] -> [0, 10, 40, 10]
};

/*
i.convertEq = {|f, settings|
// [high, highFreq, mid, midFreq, low]
var high = settings[4];
var highFreq = settings[3];
var mid = settings[2];
var midFreq = settings[1];
var low = settings[0];
var eqArray = Array2D.new(2,4);
eqArray = [[0, midFreq, highFreq, 1], [low, mid, mid, high]];
};*/

// ControlSpec map only with 0..1.0 as source
i.mapMidFreq = ControlSpec(20, 50, \lin);
i.mapHighFreq = ControlSpec(30, 60, \lin);
i.unConvertEq = {|f, settings|
	// [ 1, 2, 3, 4, horizontal1, horizontal2 ], values == 0-100
	var high = settings[3];
	var highFreq = i.mapHighFreq.map(settings[5]/100).asInteger;
	var mid = ((settings[1] + settings[2]) / 2).asInteger;
	var midFreq = i.mapMidFreq.map(settings[4]/100).asInteger;
	var low = settings[0];
	var eqArray = Array.fill(5);
	eqArray = [low, midFreq, mid, highFreq, high];
};



////////////////////////////////////////////////////////////
// SCAN SERIAL PORTS FUNCTION
i.scanSerials = {
	var deviceName = Array.fill(3, nil);
	i.allSerialDevices = SerialPort.devices;
	i.serialCount = 0;
	i.allSerialDevices.do({|dev|
		// check if tty
		if (dev.split($/)[2].split($.)[0] == "tty", {
			// check namespace
			if (dev.split($.)[1].beginsWith("SLAB"), {
				// dev.postln;
				// i.tangibleDevices[i.serialCount] = [dev, "name", "port", "routine"];
				deviceName[i.serialCount] = dev;
				i.serialCount = i.serialCount + 1;
			});
		});
	});

	// ("scan serial. deviceName: " + deviceName + " SerialCount:" + i.serialCount).postln;
	i.tangibleDevices = Array.fill(i.serialCount, nil);
	i.serialCount.do({|c|
		i.tangibleDevices[c] = ('serial': deviceName[c], 'name': nil, 'port': nil, 'routine': nil, 'assigned': false);  // object instead of array
	});


	i.tangibleDevices.do({|dev, c|
		if (dev[\serial] != nil, {
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
						// content = arr;
						content = Array.fill(arr.size);
						arr.do({|entry, c|
							content[c] = entry.asInteger;
						});


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





////////////////////////////////////////////////////////////
// DISPLAY DEVICES - display devices once they are recognized
i.displaySerialDevices = {
	var assigned = 0, displayed = 0;
	i.tangibleDevices.do{|dev|
		if (dev[\assigned]==true, {assigned = assigned + 1});
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
		if (displayed > (i.serialCount-1), {
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
					MIDIIn.addFuncTo(\control, ~midiInFunction);
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
			i.sendSerial( ('device': "fader", 'content': i.faderEq) );
		});
		if (string == "env", {
			i.stringDest = "env";
			i.destEq.states_([["EQ", Color.black, Color.white]]);
			i.destEnv.states_([["ENV", Color.black, Color.green]]);
			i.sendSerial( ('device': "fader", 'content': i.faderEnv) );
		});
	}
};
// update MIDI Channels
i.updateMidiChannels = {|f, message|
	("update midi channels message: " + message).postln;
	if (message == 1, {
		i.midiSendChannel = 1;
		i.midiReceiveChannel = 0;
	});
	if (message == 0, {
		i.midiSendChannel = 0;
		i.midiReceiveChannel = 1;
	});
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

	// MIDI send channels, buttons
	StaticText.new(i.upperHalfView, Rect(300, 65, 290, 60)).stringColor_(Color.white).string_("channels");
	i.channelSelector = Button(i.upperHalfView,Rect(280, 107, 75, 20)).states_([[">2 | 1>", Color.black, Color.white],[">1 | 2>", Color.black, Color.white]])
	.action_({|b|
		defer {i.updateMidiChannels(b.value)}
	});

};
i.makeWindow.value;
i.startMIDI.value;
defer {
	i.updateStringDestination("eq");
};

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
SerialPort.listDevices;

Check device:
"/dev/tty.SLAB_USBtoUART".split($/)[2];
"/dev/tty.SLAB_USBtoUART".split($/)[2].split($.)[0] == "tty";
Check the name:
"/dev/tty.SLAB_USBtoUART".split($.);
"/dev/tty.SLAB_USBtoUART".split($.)[1];
"/dev/tty.SLAB_USBtoUART".split($.)[1].beginsWith("SLAB");

*/