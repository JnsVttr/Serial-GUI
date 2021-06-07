
////////////////////////////////////////////////////////////
// Tangible Signals - Serial Ports GUI /////////////////////
////////////////////////////////////////////////////////////

(
/*
bugs:
STRING device: weird wrong reading on fader 1, jumps from normal to very low..
when only "wheel" connected, than on MIDI In -> GUI value display "wheel" shows string values


Troubles: feedback loop - midi to device, device updates serial, serial sends to midi
> for wheel (startposition message could help?)
> no problems with pattern pin
> true for envelope
*/

// Welle website sends MIDI at: 2 (1-16), receives MIDI at: 1 (1-16)
// Emulation. sends MIDI at: 0 (0-15), receives MIDI at 1 (0-15)
// SerialGUI: sends MIDI at: 1 (0-15), receives MIDI at 0 (0-15)








////////////////////////////////////////////////////////////
// VARIABLES ///////////////////////////////////////////////
////////////////////////////////////////////////////////////

// SerialPort.listDevices;
i = (); // all functions
i.midiConnected = false; // true if MIDI is connected
// send-receive channels to be adapted: send to WELLE (1) receive (0); send to Emulation (0), receive (1)
i.midiSendChannel = 0;
i.midiReceiveChannel = 1;
i.stringDest = "eq"; // destination for eq or env
i.tempMidiVol = 0;
i.tempMidiEq = 0; // sum
i.tempMidiEnv = 0;  // sum

// global vars
i.pattern = [0,0,0,0,0,0,0,0];
i.volume = 0.1;  // 425 * 0.296 = 126
i.faderVal = [0,0,0,0,0,0];

// store String params
// ENV
i.midiInEnv = [ 40,40,30,40 ];  // CC message 0-126 [atk dec sus rel]
i.midiEnv = [ 0.5, 0.25, 0.52, 0.7];
i.faderEnv = [0, 90, 30, 0, 30, 30];
i.envIndex = 0; // index for midi input messages EQ, empty after message
// EQ
i.midiInEq  = [ 40,40,30,40,0];  // CC message 0-126
i.midiEq  = [ 0.2, 0.15, 0.35, 0.64, 0.5 ];  // 5 values -> low, midFrew, mid, highFreq, high
i.faderEq = [50, 50, 50, 50, 50, 100];    // 6 values -> fader1, fader2, fader3, fader4, horiz1, horiz2
i.eqIndex = 0; // index for midi input messages EQ, empty after message

// store incoming midi pattern
i.midiPattern = [0,0,0,0,0,0,0,0];

i.serialDisplay = Array.fill(6, nil); // Array for serial name + values, e.g. "> pin [0,0,1,1,0,1,0,1]















////////////////////////////////////////////////////////////
// MIDI ////////////////////////////////////////////////////
////////////////////////////////////////////////////////////




////////////////////////////////////////////////////////////
// MIDI INPUT function, chan 0-15
////////////////////////////////////////////////////////////
i.assignMIDIFunction = {
	~midiInFunction = { |src, chan, num, val|
		//['MIDIIn', chan, num, val].postln;
		if (chan==i.midiReceiveChannel, {
			// ['> MIDIIn > control', chan,num,val].postln;

			// WHEEL
			if (num==9, {
				['MIDIIn volume', num, val].postln;
				i.sendSerial( ('device': "wheel", 'content': val) );
				//i.volume = val/126;
			});

			// PIN
			if ((num>=1) && (num<=8), {
				var index = num-1;
				i.midiPattern[index] = val;
				//i.sendSerial( ('device': "pin", 'content': i.midiPattern) );
				if (index == 7, {
					['MIDIIn pattern', i.midiPattern].postln;
					i.sendSerial( ('device': "pin", 'content': i.midiPattern) );
				});
			});

			// STRING
			if ((num>=10) && (num<=14), {
				var index = num-10;
				var faderArray;
				i.midiInEq[index] = val;
				faderArray = i.convertEq(i.midiInEq);
				i.eqIndex = i.eqIndex + 1;
				// ("i.eqIndex: " + i.eqIndex).postln;
				// if 5 messages arrived
				if (i.eqIndex==5, {
					['MIDIIn i.midiInEq', i.midiInEq, " converted to faderArray: ", faderArray].postln;
					// store values for Eq/Env switch, exclusive first int (is command)
					6.do({|c| i.faderEq[c]=faderArray[c]});
					if (i.stringDest == "eq", {
						i.sendSerial( ('device': "string", 'content': faderArray) );
					});
					i.eqIndex = 0;
				});
			});

			if ((num>=16) && (num<=19), {
				var index = num-16;
				var faderArray;
				i.midiInEnv[index] = val;
				faderArray = i.convertEnv(i.midiInEnv);
				i.envIndex = i.envIndex + 1;
				// ("i.envIndex: " + i.envIndex).postln;
				// if 4 messages arrived (atk dec sus rel)
				if (i.envIndex==4, {
					// store values for Eq/Env switch, exclusive first int (is command)
					6.do({|c| i.faderEnv[c]=faderArray[c]});
					['MIDIIn i.midiInEnv', i.midiInEnv, " converted to faderArray: ", faderArray].postln;
					if (i.stringDest == "env", {
						i.sendSerial( ('device': "string", 'content': faderArray) );
					});
					i.envIndex = 0;
				});
			});
		});
	};
};


////////////////////////////////////////////////////////////
// SEND MIDI FUNCTION
////////////////////////////////////////////////////////////
// send/ receive : channel 1 + 2
/*
i.sendMIDI( ('command': 'sendPattern', 'content': [1,1,1,1,0,0,0,0]) );
i.sendMIDI( ('command': 'sendEq', 'content': [0,30,50,20,70]) );
*/
i.sendMIDI = {|f, message|
	var command = message[\command];
	var content = message[\content];

	if (i.midiConnected, {
		switch(command,
			'sendVolume', {
				// send less values, only 0.1, 0.2, .. 1.0, e.g. CC 10, 20, .. 126
				if ( (content % 5) == 0, {
					if (i.tempMidiVol != content, {
						// ("sendMidi - message: " + message).postln;
						i.midiOut.control(i.midiSendChannel, 9, content);
						i.tempMidiVol = content;
					});
				});
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
				// ("send EQ: " + newEq).postln;
				for (0, 4, {|c|
					var cc = c+10;  // midi control Eq = cc 10-14
					i.midiOut.control(i.midiSendChannel, cc, newEq[c]);
				});
			},
			'sendEnv', {
				var newEnv = content;
				if (i.tempMidiEnv != content, {
					for (0, 3, {|c|
						var cc = c+16;  // midi control Env = cc 16-19
						i.midiOut.control(i.midiSendChannel, cc, newEnv[c]);
					});
					i.tempMidiEnv = content;
				});
			};
		);
	});
};



////////////////////////////////////////////////////////////
// START MIDI function
////////////////////////////////////////////////////////////

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
					i.assignMIDIFunction.value;
					MIDIIn.addFuncTo(\control, ~midiInFunction);
				});
			});
		};
	};
};


















////////////////////////////////////////////////////////////
// SERIAL //////////////////////////////////////////////////
////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////
// SERIAL SEND FUNCTION
////////////////////////////////////////////////////////////
/*
i.sendSerial( ('device': "string", 'content': [0,50,70,50,30,10]) );
i.sendSerial( ('device': "wheel", 'content': 10) );
i.sendSerial( ('device': "pin", 'content': [1,1,1,1,0,0,1,1]) );
*/
// i.tangibleDevices[0][\port].putAll("0,50,50,50,50,30,80!");
i.sendSerial = {|f, message|
	var device = message[\device];
	var command = message[\command];
	var content = message[\content];
	var pos=0;
	// extract pos
	i.tangibleDevices.do({|dev, c| if (dev[\name]==device, {pos=c})});

	// ("send to Serial ...").postln;
	switch(device,
		"string", {
			var serialString = "", port;
			serialString = serialString + "0,"; // start with command "0" to receive positions
			// add values as string
			content.do({|e, c|
				serialString = serialString + e;
				if (c<5, {serialString = serialString + ",";});
			});
			// remove white space
			serialString = serialString.replace(" ", "");
			serialString = serialString + "!";
			("send to Serial String: " + serialString).postln;
			i.tangibleDevices.do({|dev, c|
				if (dev[\name]=="string" && dev[\assigned]==true, {
					port = i.tangibleDevices[c][\port];
					port.putAll(serialString);
					dev[\inProgress] = true;
					Routine({0.5.wait; dev[\inProgress] = false; port.putAll("!");}).play;
			})});
			// update display value
			if (i.stringDest == "env", {
				i.updateDisplayValues(('device': device, 'pos': pos, 'content': i.faderEnv));
			});
			if (i.stringDest == "eq", {
				i.updateDisplayValues(('device': device, 'pos': pos, 'content': i.faderEq));
			});


		},
		"wheel", {
			// command = 1 for setting startpoint
			var serialString = "1, ", port;
			serialString = serialString + (content * 3.37).asInteger.asString + ", 0, 40, 3000";
			("send to serial wheel: " + serialString).postln;
			i.tangibleDevices.do({|dev, c|
				if (dev[\name]=="wheel" && dev[\assigned]==true, {
					dev[\inProgress] = true;
					port = i.tangibleDevices[c][\port];
					port.putAll(serialString);
			})});
			// i.tangibleDevices[0][\port].putAll("/wheel/startPos, 100, 0, 400, 2000");  // (command, position, revolution, fade in, speed)
			// update display value
			i.updateDisplayValues(('device': device, 'pos': pos, 'content': content/126));
		},
		"pin", {
			var serialString = "", port;
			content.do({|e|
				serialString = serialString + e.asString;
			});
			serialString = serialString + "!";
			serialString = serialString.replace(" ", "");
			// ("serialString: " + serialString).postln;
			("send to serial pin: " + serialString).postln;
			i.tangibleDevices.do({|dev, c|
				if (dev[\name]=="pin" && dev[\assigned]==true, {
					// ["serialString: ", serialString].postln;
					i.tangibleDevices[c][\port].putAll(serialString);
					// i.tangibleDevices[c][\port].putAll("10011010!");
				});
			});
			// update display value
			i.updateDisplayValues(('device': device, 'pos': pos, 'content': content));
		}
	);
};




////////////////////////////////////////////////////////////
// SERIAL INPUT FUNCTION
////////////////////////////////////////////////////////////

// i.serialFunction( ('count': c, 'name': deviceName, 'command': command, 'content': content) );
i.serialFunction = {|f, message|
	var device = message[\name]; // e.g. "pin", "wheel" or "fader"
	var content = message[\content]; // array, e.g. [1,1,1,1,1,1,1,1], [ 182, 0, 0], [ 0, 12, 12, 33, 43, 12]
	var pos = message[\pos];
	var command; // e.g. /pin, /wheel/startPos
	var stringMoved = false;
	var vol, eq, env;

	// ("Serial Function: message = " + message).postln;

	if (device == "pin", {
		if (content.size > 1, {
			i.sendMIDI( ('command': 'sendPattern', 'content': content) );
			// update i.midiPattern
			8.do({|c|
				i.midiPattern[c] = content[c];
			});
			// update display value
			i.updateDisplayValues(('device': device, 'pos': pos, 'content': i.midiPattern));
		});
	});

	if (device == "wheel", {
		command = content[0].asInteger;
		// incoming wheel position
		if ( command == 0, {
			if (i.tangibleDevices[pos][\inProgress]==false, {
				if (content.size > 1, {
					vol = ((content[1].asInteger) * 0.296).asInteger; // asInteger: get rid of decimals
					i.sendMIDI( ('command': 'sendVolume', 'content': vol) );
					// ("serial func: wheel vol: " + vol + " command: " + command).postln;
					// update display value
					i.volume = vol/126;
					i.updateDisplayValues(('device': device, 'pos': pos, 'content': i.volume));
				});
			});
		});
		// incoming "reached startpoint" indicator
		if (command==1, {
			// reset inProgress to let wheel messages through with short delay
			Routine({0.5.wait; i.tangibleDevices[pos][\inProgress]=false; }).play;
		});
	});

	if (device == "string", {
		var newEq, newEnv;
		if (i.tangibleDevices[pos][\inProgress]==false, {
			if (content.size == 6, {
				if (i.stringDest == "eq", {
					newEq = i.unConvertEq(content);
					i.sendMIDI( ('command': 'sendEq', 'content': newEq) );
					// store for keeping Int/ Float values for switching Eq/Env
					content.do({|e, c| i.faderEq[c] = e});
					newEq.do({|e, c| i.midiEq[c] = e});
					// update display value
					i.updateDisplayValues(('device': device, 'pos': pos, 'content': i.faderEq));
				});
				if (i.stringDest == "env", {
					newEnv = i.unConvertEnv(content);
					i.sendMIDI( ('command': 'sendEnv', 'content': newEnv) );
					// store for keeping Int/ Float values for switching Eq/Env
					content.do({|e, c| i.faderEnv[c] = e});
					newEnv.do({|e, c| i.midiEnv[c] = e});
					// update display value
					i.updateDisplayValues(('device': device, 'pos': pos, 'content': i.faderEnv));
				});
			});
		});
	});
};


////////////////////////////////////////////////////////////
// SERIAL - MIDI converters EQ / ENV
////////////////////////////////////////////////////////////
/*
(i.mapAttack.unmap(10)*100).asInteger
*/
i.mapAttack = ControlSpec(5, 50, \lin);
i.mapDecay = ControlSpec(20, 60, \lin);
i.convertEnv = {|f, settings|
	// midi in 0-126 [atk, dec, sus, rel]
	var envArray = Array.fill(6, nil);
	var fader2 = settings[2];
	var fader3 = settings[3];
	var fader4 = (i.mapAttack.unmap(settings[0])*100).asInteger;
	var fader5 = (i.mapAttack.unmap(settings[1])*100).asInteger;
	envArray = [ 0, 126, fader2, fader3, fader4, fader5 ];
};
i.unConvertEnv = {|f, fader|
	// device: [ 1, 2, 3, 4, horizontal1, horizontal2 ]
	// Emulation only: [ [ 0, 0.1, 0.6, 1 ], [ 0, 1, 0.4, 0 ] ] -> [0,atk,atk+dec,atk+dec+rel,1]      [0,1,sus,sus,0]
	// SerialGUI: [horizontal1, horizontal2-horizontal1, 3, 4]
	// .. 1 = 0, 2 = volume. (Volume is tricky, corresponds to Volume wheel. How to embed?)
	var envArray = Array.new(4);
	var atk = i.mapAttack.map(fader[4]/126).asInteger;
	var dec = i.mapDecay.map(fader[5]/126).asInteger - atk;
	var sus = fader[2];
	var rel = fader[3];
	envArray = [ atk, dec, sus, rel ]; // as * 126 [0, 0.1, 0.4, 0.1] -> [0, 10, 40, 10]
};

// EQ:
// ControlSpec map only with 0..1.0 as source
i.mapMidFreq = ControlSpec(20, 50, \lin);
i.mapHighFreq = ControlSpec(30, 60, \lin);
i.convertEq = {|f, settings|
	// incoming 0-126 -> [low, midFreq, mid, highFreq, high] (size=5)
	var high = settings[4].asInteger;
	var highFreq = settings[3].asInteger;
	var mid = settings[2].asInteger;
	var midFreq = settings[1].asInteger;
	var low = settings[0].asInteger;
	var eqArray = Array.fill(6, nil);
	// output for device: 0-126
	eqArray = [low, mid, mid, high, midFreq, highFreq];
};
i.unConvertEq = {|f, settings|
	// [ 1, 2, 3, 4, horizontal1, horizontal2 ], values == 0-100
	var high = settings[3];
	var highFreq = i.mapHighFreq.map(settings[5]/126).asInteger;
	var mid = ((settings[1] + settings[2]) / 2).asInteger;
	var midFreq = i.mapMidFreq.map(settings[4]/126).asInteger;
	var low = settings[0];
	var eqArray = Array.fill(5);
	eqArray = [low, midFreq, mid, highFreq, high];
};





////////////////////////////////////////////////////////////
// SCAN SERIAL PORTS FUNCTION
////////////////////////////////////////////////////////////

i.scanSerials = Routine({
	var deviceName = Array.fill(3, nil);
	var allTty = "";

	i.allSerialDevices = SerialPort.devices;
	1.wait;
	i.serialCount = 0;

	i.allSerialDevices.do({|dev|
		// check if tty
		if (dev.split($/)[2].split($.)[0] == "tty", {
			allTty = allTty + dev.asString + "\n";
			// check namespace
			if (dev.split($.)[1].beginsWith("SLAB"), {
				// dev.postln;
				// i.tangibleDevices[i.serialCount] = [dev, "name", "port", "routine"];
				deviceName[i.serialCount] = dev;
				i.serialCount = i.serialCount + 1;
			});
		});
	});
	("All serial devices tty: \n" + allTty + " count SLAB: " + i.serialCount).postln;

	// ("scan serial. deviceName: " + deviceName + " SerialCount:" + i.serialCount).postln;
	i.tangibleDevices = Array.fill(i.serialCount, nil);
	i.serialCount.do({|c|
		i.tangibleDevices[c] = (
			'serial': deviceName[c],
			'name': nil,
			'port': nil,
			'routine': nil,
			'assigned': false,
			'inProgress': false,
			'pos': c,
			'display': nil);  // object instead of array
	});

	("Tangible Devices: " + i.tangibleDevices).postln;

	// assign serial port devices
	i.tangibleDevices.do({|dev, c|
		if (dev[\serial] != nil, {
			"Open serial port for: ".post; dev[\serial].postln;
			dev[\port] = SerialPort(
				dev[\serial],
				baudrate: 115200,
				crtscts: true);
			dev[\port].doneAction = { (dev[\serial] + " - serial port got closed").postln; };
		});
	});

	1.wait;

	// ID devices + serial input
	("init serial Routine...").postln;

	i.serialCount.do({|c|
		Routine({
			var byte, str, arr, id, deviceName, command, content, message;
			inf.do{

				var dev = i.tangibleDevices[c];
				if(dev[\port].read==10, {
					str = "";
					while({byte = dev[\port].read; byte !=13 }, {
						str = str++byte.asAscii;
					});
					// ("Raw serial input 'str': " + str).postln;

					// SERIAL INPUT
					if (dev[\assigned], {
						deviceName = dev[\name];
						// serial INPUT
						// split string into array
						arr = str.split($,);
						// extract content from arr, convert to integers
						content = Array.fill(arr.size);
						arr.do({|entry, c| content[c] = entry.asInteger; });

						message = ('name': deviceName, 'content': content, 'pos': dev[\pos]);
						// ("serial input message: " + message).postln;
						i.serialFunction( message );
					});

					// ID + display
					if (dev[\assigned]==false, {
						if ((str=="pin") || (str=="wheel") || (str=="string"), {
							"Tangible Devices - assign ID: ".post;
							dev[\serial].postln;
							dev[\name] = str;
							dev[\assigned] = true;
							dev[\display] = i.serialDisplay[dev[\pos]+3]; // display for messages
							defer {if (i.window.isClosed == false, {
								i.displaySerialDevices( ('name': dev[\name], 'pos': dev[\pos], 'display': dev[\display]));
							});};
						});
					});
				});
			};
		}).play;
	});


	1.wait;

	i.tangibleDevices.do({|dev, c|
		if (dev[\serial] != nil, {
			var time = (c+1) * 0.4;
			// send ID command
			Routine({
				time.wait;
				dev[\port].putAll("x");
				dev[\port].putAll("x");
				time.wait;
				dev[\port].putAll("9");
				time.wait;
				dev[\port].putAll("9");
				time.wait;
				dev[\port].putAll("9");
			}).play;
		});
	});

	defer { i.serialIndex.string = "connected: " + i.serialCount; };
});






















////////////////////////////////////////////////////////////
// DISPLAYS ////////////////////////////////////////////////
////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////
// DISPLAY DEVICES - display devices once they are recognized
// i.displaySerialDevices( ('name': dev[\name], 'pos': dev[\pos], 'display': dev[\display]));
i.displaySerialDevices = {|f, message|
	var name = message.name;
	var pos = message.pos;
	var display = message.display;
	defer {
		i.serialDisplay[pos].string = "> " + name;
		switch(name,
			"pin", {i.serialDisplay[pos+3].string = i.pattern.asString.replace("[", "").replace("]", "");},
			"wheel", {i.serialDisplay[pos+3].string = i.volume.asString;},
			"string", {i.serialDisplay[pos+3].string = i.faderVal.asString.replace("[", "").replace("]", "");},
		);
	}
};
i.updateDisplayValues = {|f, message|
	var pos = message.pos;
	var content = message.content;
	var device = message.device;
	if (device=="wheel", {content = content.round(0.01)});
	content = content.asString;
	content = content.replace("[", "").replace("]", "");
	defer {
		i.serialDisplay[pos+3].string = content;
	};
};


// update string destination
i.updateStringDestination = {|f, string|
	var faderArray = Array.fill(6, 0);
	defer {
		if (string == "eq", {
			i.stringDest = "eq";
			i.destEq.states_([["EQ", Color.black, Color.green]]);
			i.destEnv.states_([["ENV", Color.black, Color.white]]);
			// 6.do({|c| faderArray[c+1] = i.faderEq[c]});
			i.tangibleDevices.do({|dev, c| if (dev[\name]=="string", {
				i.sendSerial( ('device': "string", 'content': i.faderEq) );
			})});
		});
		if (string == "env", {
			i.stringDest = "env";
			i.destEq.states_([["EQ", Color.black, Color.white]]);
			i.destEnv.states_([["ENV", Color.black, Color.green]]);
			// 6.do({|c| faderArray[c] = i.faderEnv[c]});
			i.tangibleDevices.do({|dev, c| if (dev[\name]=="string", {
				i.sendSerial( ('device': "string", 'content': i.faderEnv) );
			})});
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
// WINDOW
////////////////////////////////////////////////////////////

i.makeWindow = {
	// main window
	i.window = Window.new("Tangible Signals - Serial Manager", Rect(10, 1910, 360, 240))
	.front
	.background_(Color.white);

	// interaction:
	i.upperHalfView = CompositeView(i.window, Rect(0,0,530,240)).background_(Color.black);

	// scan serial
	i.scanSerialButton = Button(i.upperHalfView,Rect(10, 16, 100, 30)).states_([["scan devices", Color.black, Color.white]])
	.action_({|b|
		i.scanSerials.play;
	});
	// serial state
	i.serialIndex = StaticText.new(i.upperHalfView, Rect(15, 35, 290, 60)).stringColor_(Color.white).string_("");
	i.serialList = StaticText.new(i.upperHalfView, Rect(10, 60, 90, 60)).stringColor_(Color.white).string_("");
	3.do({|c|
		var height = ((c+1) * 30) + 80;
		i.serialDisplay[c] = StaticText.new(i.upperHalfView, Rect(10, height, 90, 60)).stringColor_(Color.white).string_(">");
	});
	3.do({|c|
		var height = ((c+1) * 30) + 80;
		c = c+3;
		i.serialDisplay[c] = StaticText.new(i.upperHalfView, Rect(80, height, 190, 60)).stringColor_(Color.white).string_(". . .");
	});

	// MIDI input choose
	i.popup = PopUpMenu(i.upperHalfView, Rect(140, 16, 190, 30));
	i.popup.stringColor_(Color.black);   // only changes the look of displayed item
	i.popup.font_(Font("Courier", 13));   // only changes the look of displayed item

	// string destination buttons
	StaticText.new(i.upperHalfView, Rect(140, 35, 290, 60)).stringColor_(Color.white).string_("string destination");
	i.destEq = Button(i.upperHalfView,Rect(140, 80, 60, 20)).states_([["EQ", Color.black, Color.white]])
	.action_({|b|
		defer {i.updateStringDestination("eq");}
	});
	i.destEnv = Button(i.upperHalfView,Rect(210, 80, 60, 20)).states_([["ENV", Color.black, Color.white]])
	.action_({|b|
		defer {i.updateStringDestination("env");}
	});

	// MIDI send channels, buttons
	StaticText.new(i.upperHalfView, Rect(300, 35, 290, 60)).stringColor_(Color.white).string_("channels");
	i.channelSelector = Button(i.upperHalfView,Rect(280, 80, 75, 20)).states_([[">2 | 1>", Color.black, Color.white],[">1 | 2>", Color.black, Color.white]])
	.action_({|b|
		defer {i.updateMidiChannels(b.value)}
	});

};









////////////////////////////////////////////////////////////
// INIT PROGRAM ////////////////////////////////////////////
////////////////////////////////////////////////////////////

i.makeWindow.value;
i.startMIDI.value;
defer {
	i.updateStringDestination("eq");
};







// EOF
)

