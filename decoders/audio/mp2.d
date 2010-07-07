/*
 * mp2.d
 *
 * This file implements the MP2 audio standard.
 *
 * Author: Dave Wilkinson
 *
 */

module decoders.audio.mp2;

import decoders.audio.decoder;
import decoders.decoder;

import core.stream;
import core.time;
import core.string;
import core.definitions;

import io.wavelet;
import io.audio;
import io.console;

// initialize the array to zero
typedef double zerodouble = 0.0;

// 2
template FromBigEndian(uint input) {
	version (LittleEndian) {
		const auto FromBigEndian = (input >> 24) | ((input >> 8) & 0x0000FF00) | ((input << 8) & 0x00FF0000) | ((input << 24) & 0xFF000000);
	}
	else {
		const auto FromBigEndian = input;
	}
}

template FromBigEndianBitIndex32(uint index) {
	version (LittleEndian) {
		const auto FromBigEndianBitIndex32 = ((3 - cast(uint)(index/8)) * 8) + (index % 8);
	}
	else {
		const auto FromBigEndianBitIndex32 = index;
	}
}

private {
	}



// Section: Codecs/Audio

// Description: This is the MPEG Layer 2 audio codec.
class MP2Decoder : AudioDecoder {
private:
	// for the classes of quantization table
	struct QuantizationClass {
		uint numberOfSteps;
		double C;
		double D;
		bool grouping;
		uint samplesPerCodeword;
		uint bitsPerCodeword;
	}

	static const uint bitMasks[] = [
		0,
		1 << 0,
		1 << 1,
		1 << 2,
		1 << 3,
		1 << 4,
		1 << 5,
		1 << 6,
		1 << 7,
		1 << 8,
		1 << 9,
		1 << 10,
		1 << 11,
		1 << 12,
		1 << 13,
		1 << 14,
		1 << 15,
		1 << 16,
		1 << 17,
		1 << 18,
		1 << 19,
		1 << 20,
		1 << 21,
		1 << 22,
		1 << 23,
		1 << 24,
		1 << 25,
		1 << 26,
		1 << 27,
		1 << 28,
		1 << 29,
		1 << 30,
		1 << 31,
	];

	static const uint bitFills[] = [
		0,
		(1 << 0) - 1,
		(1 << 1) - 1,
		(1 << 2) - 1,
		(1 << 3) - 1,
		(1 << 4) - 1,
		(1 << 5) - 1,
		(1 << 6) - 1,
		(1 << 7) - 1,
		(1 << 8) - 1,
		(1 << 9) - 1,
		(1 << 10) - 1,
		(1 << 11) - 1,
		(1 << 12) - 1,
		(1 << 13) - 1,
		(1 << 14) - 1,
		(1 << 15) - 1,
		(1 << 16) - 1,
		(1 << 17) - 1,
		(1 << 18) - 1,
		(1 << 19) - 1,
		(1 << 20) - 1,
		(1 << 21) - 1,
		(1 << 22) - 1,
		(1 << 23) - 1,
		(1 << 24) - 1,
		(1 << 25) - 1,
		(1 << 26) - 1,
		(1 << 27) - 1,
		(1 << 28) - 1,
		(1 << 29) - 1,
		(1 << 30) - 1,
		(1 << 31) - 1,
	];

	/+
		/* 0 */		{ 3, 1.33333333333, 0.50000000000,  true, 3, 5 },
		/* 1 */		{ 5, 1.60000000000, 0.50000000000,  true, 3, 7 },
		/* 2 */		{ 7, 1.14285714286, 0.25000000000, false, 1, 3 },
		/* 3 */		{ 9, 1.77777777777, 0.50000000000,  true, 3, 10},
		/* 4 */		{15, 1.06666666666, 0.12500000000, false, 1, 4 },
		/* 5 */		{31, 1.03225806452, 0.06250000000, false, 1, 5 },
		/* 6 */		{63, 1.01587301587, 0.03125000000, false, 1, 6 },
		/* 7 */		{127, 1.00787401575, 0.01562500000, false, 1, 7 },
		/* 8 */		{255, 1.00392156863, 0.00781250000, false, 1, 8 },
		/* 9 */		{511, 1.00195694716, 0.00390625000, false, 1, 9 },
		/* 10 */	{1023, 1.00097751711, 0.00195312500, false, 1, 10 },
		/* 11 */	{2047, 1.00048851979, 0.00097656250, false, 1, 11 },
		/* 12 */	{4095, 1.00024420024, 0.00048828125, false, 1, 12 },
		/* 13 */	{8191, 1.00012208522, 0.00024414063, false, 1, 13 },
		/* 14 */	{16383, 1.00006103888, 0.00012207031, false, 1, 14 },
		/* 15 */	{32767, 1.00003051851, 0.00006103516, false, 1, 15 },
		/* 16 */	{65535, 1.00001525902, 0.00003051758, false, 1, 16 },
		/* 17 */	{ 0, 1.33333333333, 0.50000000000,  true, 3, 5 },

	struct QuantizationClass
	{
		uint numberOfSteps;
		double C;
		double D;
		bool grouping;
		uint samplesPerCodeword;
		uint bitsPerCodeword;
	}

	+/

	// GDC doesn't like a static array of the QuantizationClass struct
	// I dunno why

	static const QuantizationClass quantizationClass0 = { 3, 1.33333333333, 0.50000000000,  true, 3, 5 };
	static const QuantizationClass quantizationClass1 = { 5, 1.60000000000, 0.50000000000,  true, 3, 7 };
	static const QuantizationClass quantizationClass2 = { 7, 1.14285714286, 0.25000000000, false, 1, 3 };
	static const QuantizationClass quantizationClass3 = { 9, 1.77777777777, 0.50000000000,  true, 3, 10};
	static const QuantizationClass quantizationClass4 = {15, 1.06666666666, 0.12500000000, false, 1, 4 };
	static const QuantizationClass quantizationClass5 = {31, 1.03225806452, 0.06250000000, false, 1, 5 };
	static const QuantizationClass quantizationClass6 = {63, 1.01587301587, 0.03125000000, false, 1, 6 };
	static const QuantizationClass quantizationClass7 = {127, 1.00787401575, 0.01562500000, false, 1, 7 };
	static const QuantizationClass quantizationClass8 = {255, 1.00392156863, 0.00781250000, false, 1, 8 };
	static const QuantizationClass quantizationClass9 = {511, 1.00195694716, 0.00390625000, false, 1, 9 };
	static const QuantizationClass quantizationClass10 = {1023, 1.00097751711, 0.00195312500, false, 1, 10 };
	static const QuantizationClass quantizationClass11 = {2047, 1.00048851979, 0.00097656250, false, 1, 11 };
	static const QuantizationClass quantizationClass12 = {4095, 1.00024420024, 0.00048828125, false, 1, 12 };
	static const QuantizationClass quantizationClass13 = {8191, 1.00012208522, 0.00024414063, false, 1, 13 };
	static const QuantizationClass quantizationClass14 = {16383, 1.00006103888, 0.00012207031, false, 1, 14 };
	static const QuantizationClass quantizationClass15 = {32767, 1.00003051851, 0.00006103516, false, 1, 15 };
	static const QuantizationClass quantizationClass16 = {65535, 1.00001525902, 0.00003051758, false, 1, 16 };
	static const QuantizationClass quantizationClass17 = { 0, 1.33333333333, 0.50000000000,  false, 3, 5 };


	// A and B

	// sb0 .. 2 (4 bits)
	const QuantizationClass allocationToQuantA1[] = [ quantizationClass17, quantizationClass0, quantizationClass2, quantizationClass4,
					quantizationClass5, quantizationClass6, quantizationClass7, quantizationClass8, quantizationClass9,
					quantizationClass10, quantizationClass11, quantizationClass12, quantizationClass13, quantizationClass14,
					quantizationClass15, quantizationClass16 ];

	// sb3 .. 10 (4 bits)
	const QuantizationClass allocationToQuantA2[] = [ quantizationClass17, quantizationClass0, quantizationClass1, quantizationClass2, quantizationClass3, quantizationClass4,
					quantizationClass5, quantizationClass6, quantizationClass7, quantizationClass8, quantizationClass9,
					quantizationClass10, quantizationClass11, quantizationClass12, quantizationClass13, quantizationClass16 ];
	// sb11 .. 22 (3 bits)
	const QuantizationClass allocationToQuantA3[] = [ quantizationClass17, quantizationClass0, quantizationClass1, quantizationClass2, quantizationClass3, quantizationClass4,
					quantizationClass5, quantizationClass6, quantizationClass7, quantizationClass8, quantizationClass9,
					quantizationClass10, quantizationClass11, quantizationClass12, quantizationClass13, quantizationClass16 ];
	// sb23 .. sb26 or sb29 (2 bits)
	const QuantizationClass allocationToQuantA4[] = [ quantizationClass17, quantizationClass0, quantizationClass1, quantizationClass16 ];

	// sblimit = 27 (A)
	// sblimit = 30 (B)

	// C and D

	// sb0 .. sb1 (4 bits)
	const QuantizationClass allocationToQuantC1[] = [ quantizationClass17, quantizationClass0, quantizationClass1, quantizationClass3,
					quantizationClass4,
					quantizationClass5, quantizationClass6, quantizationClass7, quantizationClass8, quantizationClass9,
					quantizationClass10, quantizationClass11, quantizationClass12, quantizationClass13, quantizationClass14,
					quantizationClass15 ];

	// sb2 .. sb7 or sb11 (3 bits)
	//const uint allocationTableC2[] = [ 0, 3, 5, 9, 15, 31, 63, 127 ]; // can refer to above table
	// sblimit = 8 (C)
	// sblimit = 12 (D)


	// Scalefactors
	const double scaleFactors[] = [ 2.00000000000000,	1.58740105196820,
									1.25992104989487,	1.00000000000000,
									0.79370052598410,	0.62996052494744,
									0.50000000000000,	0.39685026299205,
									0.31498026247372,	0.25000000000000,
									0.19842513149602,	0.15749013123686,
									0.12500000000000,	0.09921256574801,
									0.07874506561843,	0.06250000000000,
									0.04960628287401,	0.03937253280921,
									0.03125000000000,	0.02480314143700,
									0.01968626640461,	0.01562500000000,
									0.01240157071850,	0.00984313320230,
									0.00781250000000,	0.00620078535925,
									0.00492156660115,	0.00390625000000,
									0.00310039267963,	0.00246078330058,
									0.00195312500000,	0.00155019633981,
									0.00123039165029,	0.00097656250000,
									0.00077509816991,	0.00061519582514,
									0.00048828125000,	0.00038754908495,
									0.00030759791257,	0.00024414062500,
									0.00019377454248,	0.00015379895629,
									0.00012207031250,	0.00009688727124,
									0.00007689947814,	0.00006103515625,
									0.00004844363562,	0.00003844973907,
									0.00003051757813,	0.00002422181781,
									0.00001922486954,	0.00001525878906,
									0.00001211090890,	0.00000961243477,
									0.00000762939453,	0.00000605545445,
									0.00000480621738,	0.00000381469727,
									0.00000302772723,	0.00000240310869,
									0.00000190734863,	0.00000151386361,
									0.00000120155435,	1e-20	];

	const auto MPEG_SYNC_BITS 		= FromBigEndian!(0xFFF00000);
	const auto MPEG_ID_BIT    		= FromBigEndian!(0x00080000);
	const auto MPEG_LAYER			= FromBigEndian!(0x00060000);
	const auto MPEG_LAYER_SHIFT				= FromBigEndianBitIndex32!(17);
	const auto MPEG_PROTECTION_BIT	= FromBigEndian!(0x00010000);
	const auto MPEG_BITRATE_INDEX	= FromBigEndian!(0x0000F000);
	const auto MPEG_BITRATE_INDEX_SHIFT 	= FromBigEndianBitIndex32!(12);
	const auto MPEG_SAMPLING_FREQ	= FromBigEndian!(0x00000C00);
	const auto MPEG_SAMPLING_FREQ_SHIFT 	= FromBigEndianBitIndex32!(10);
	const auto MPEG_PADDING_BIT		= FromBigEndian!(0x00000200);
	const auto MPEG_PRIVATE_BIT		= FromBigEndian!(0x00000100);
	const auto MPEG_MODE			= FromBigEndian!(0x000000C0);
	const auto MPEG_MODE_SHIFT				= FromBigEndianBitIndex32!(6);
	const auto MPEG_MODE_EXTENSION	= FromBigEndian!(0x00000030);
	const auto MPEG_MODE_EXTENSION_SHIFT 	= FromBigEndianBitIndex32!(4);
	const auto MPEG_COPYRIGHT		= FromBigEndian!(0x00000008);
	const auto MPEG_ORIGINAL		= FromBigEndian!(0x00000004);
	const auto MPEG_EMPHASIS		= FromBigEndian!(0x00000003);
	const auto MPEG_EMPHASIS_SHIFT = 0;

	// modes

	const auto MPEG_MODE_STEREO			= 0;
	const auto MPEG_MODE_JOINT_STEREO	= 1;
	const auto MPEG_MODE_DUAL_CHANNEL	= 2;
	const auto MPEG_MODE_SINGLE_CHANNEL = 3;

	// layer 1
	//const auto bitRates[] = [ 0, 32, 64, 96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416, 448 ];

	// layer 2
	const uint[] bitRates = [ 0, 32, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 384, 0 ]; // the first entry is the 'free' bitrate
	const double[] samplingFrequencies = [ 44.1, 48.0, 32.0, 1.0 ]; // the final entry is reserved, but set to 1.0 due to being used in division

	const uint byteMasks[9][] = [
		[0x00, 0x00, 0x00, 0x00, 0x0, 0x0, 0x0, 0x0],		// 0 bit
		[0x80, 0x40, 0x20, 0x10, 0x8, 0x4, 0x2, 0x1],		// 1 bit
		[0xC0, 0x60, 0x30, 0x18, 0xC, 0x6, 0x3, 0x1],		// 2 bits
		[0xE0, 0x70, 0x38, 0x1C, 0xE, 0x7, 0x3, 0x1],		// 3 bits
		[0xF0, 0x78, 0x3C, 0x1E, 0xF, 0x7, 0x3, 0x1],		// 4 bits
		[0xF8, 0x7C, 0x3E, 0x1F, 0xF, 0x7, 0x3, 0x1],		// 5 bits
		[0xFC, 0x7E, 0x3F, 0x1F, 0xF, 0x7, 0x3, 0x1],		// 6 bits
		[0xFE, 0x7F, 0x3F, 0x1F, 0xF, 0x7, 0x3, 0x1],		// 7 bits
		[0xFF, 0x7F, 0x3F, 0x1F, 0xF, 0x7, 0x3, 0x1]		// 8 bits
	];

	struct MP2HeaderInformation {
		uint ID;
		uint Layer;
		uint Protected;
		uint BitrateIndex;
		uint SamplingFrequency;
		uint Padding;
		uint Private;
		uint Mode;
		uint ModeExtension;
		uint Copyright;
		uint Original;
		uint Emphasis;
	}

	const auto MP2_STATE_INIT 						= 0;
	const auto MP2_READ_HEADER						= 1;
	const auto MP2_AMBIGUOUS_SYNC					= 2;
	const auto MP2_READ_CRC							= 3;
	const auto MP2_READ_AUDIO_DATA					= 4;

	const auto MP2_BUFFER_AUDIO						= 5;

	const auto MP2_READ_AUDIO_DATA_DUAL_CHANNEL 	= 7;
	const auto MP2_READ_AUDIO_DATA_SINGLE_CHANNEL	= 8;
	const auto MP2_READ_AUDIO_DATA_JOINT_STEREO		= 9;




	// number of blocks (of 1152 samples) to buffer
	const auto NUM_BLOCKS = 80;

protected:

	bool accepted;

	uint mpeg_header;
	uint known_sync_bits;

<<<<<<< HEAD:decoders/audio/mp2.d
=======
// Description: This is the MPEG Layer 2 audio codec.
class MP2Decoder : AudioDecoder {
protected:

	bool accepted;

	uint mpeg_header;
	uint known_sync_bits;

>>>>>>> 7168ba66303a9911bd72a3752dc0134777b0ea6e:decoders/audio/mp2.d
	ushort crc;

	uint audioDataLength;

	ubyte audioData[];
	QuantizationClass* allocClass[2][32];
	uint scfsi[2][32];

	uint scalefactor[2][3][32];
	uint samplecode;
	uint sample[2][3][32];

	double quantSample[2][3][32];

	uint channels;

	uint samplesLeft;

	uint bufferSize;
	AudioFormat wf;

	Time bufferTime;

	long posOfFirstFrame;


	// bit building
	ubyte* curByte;
	uint curPos;

	MP2HeaderInformation header;

	align(1) struct ID3HeaderInformation {
		ubyte[3] signature;
		ubyte[2] ver;
		ubyte flags;
		ubyte[4] len;
	}

	ID3HeaderInformation id3;
	
	uint id3length;

	int bufOffset[2] = [64,64];

	zerodouble BB[2][2*512];

	// Import common lookup tables
	import decoders.audio.mpegCommon;

public:
	override string name() {
		return "MPEG Layer 2";
	}

	override string extension() {
		return "mp2";
	}

	StreamData decode(Stream stream, Wavelet toBuffer, ref AudioInfo wi) {
		for (;;) {
			switch (decoderState) {
				case MP2_STATE_INIT:
					//initial stuff

					decoderState = MP2_BUFFER_AUDIO;

					posOfFirstFrame = cast(long)stream.position;

					SeekPointer sptr = {Time.init, cast(ulong)posOfFirstFrame, null};
					seekLUT ~= sptr;

					// *** fall through *** //

					// attempts to find the 12-16 sync bits
					// if it is unsure of the filetype, it will
					// look for only 12 bits (b 1111 1111 1111)
					// if it knows its layer it will search for
					// the sync bits plus that part of the header

					// entry for getting another audio buffer
				case MP2_BUFFER_AUDIO:

					samplesLeft = 1152 * NUM_BLOCKS;

					bufferSize = samplesLeft * 2;

					if (isSeek && !isSeekBack && (toSeek < (curTime + bufferTime))) {
						// seeking
						Console.putln("seek no more");
						isSeek = false;
						return StreamData.Accepted;
					}
					else if (isSeek && isSeekBack && (toSeek >= curTime)) {
						// seeking
						Console.putln("seek no more");
						isSeek = false;
						return StreamData.Accepted;
					}

					decoderState = MP2_READ_HEADER;

					// *** fall through *** //

				case MP2_READ_HEADER:

					if (!stream.read(mpeg_header)) {
						if (accepted) {
							return StreamData.Accepted;
						}
						return StreamData.Required;
					}

					decoderState = MP2_AMBIGUOUS_SYNC;


					// *** fall through *** //

					// look at the sync bits of the header
					// if they are not correct, shift the header
					// 8 bits and read another byte until the
					// sync bits match

				case MP2_AMBIGUOUS_SYNC:

     				if ((mpeg_header & FromBigEndian!(0xFFFFFF00)) == FromBigEndian!(0x49443300)) {

     					if (id3.signature[0] != 0x49) {
							if (!stream.read((cast(ubyte*)&id3) + 4, id3.sizeof - 4)) {
								return StreamData.Required;
							}

							id3.signature[0] = 0x49;

							id3.ver[0] = cast(ubyte)(mpeg_header & 0xFF);

							// skip the ID3 section
							foreach(b; id3.len) {
								id3length <<= 7;
								b &= 0x7f;
								id3length |= b;
							}

							//Console.putln("id3 length: ", new String("%x", id3length));
						}

						if (!stream.skip(id3length)) {
							return StreamData.Required;
						}

						decoderState = MP2_READ_HEADER;
						continue;
					}

					if ((mpeg_header & MPEG_SYNC_BITS) == MPEG_SYNC_BITS) {
						// sync bits found
						//writeln("sync bits found ", stream.getPosition() - 4);

						// pull apart header

						// the header looks like this:

						// SYNCWORD			12 bits
						// ID				1 bit
						// LAYER			2 bits
						// PROTECTION BIT	1 bit
						// BITRATE INDEX	4 bits
						// SAMPLING FREQ	2 bits
						// PADDING BIT		1 bit
						// PRIVATE BIT		1 bit
						// MODE				2 bits
						// MODE EXTENSION	2 bits
						// COPYRIGHT		1 bit
						// ORIGINAL/HOME	1 bit
						// EMPHASIS			2 bits

						header.ID = (mpeg_header & MPEG_ID_BIT ? 1 : 0);
						header.Layer = (mpeg_header & MPEG_LAYER) >> MPEG_LAYER_SHIFT;

						if (header.Layer != 2) {
							return StreamData.Invalid;
						}

						header.Protected = (mpeg_header & MPEG_PROTECTION_BIT ? 1 : 0);
						header.BitrateIndex = (mpeg_header & MPEG_BITRATE_INDEX) >> MPEG_BITRATE_INDEX_SHIFT;
						header.SamplingFrequency = (mpeg_header & MPEG_SAMPLING_FREQ) >> MPEG_SAMPLING_FREQ_SHIFT;
						header.Padding = (mpeg_header & MPEG_PADDING_BIT ? 1 : 0);
						header.Private = (mpeg_header & MPEG_PRIVATE_BIT ? 1 : 0);
						header.Mode = (mpeg_header & MPEG_MODE) >> MPEG_MODE_SHIFT;
						header.ModeExtension = (mpeg_header & MPEG_MODE_EXTENSION) >> MPEG_MODE_EXTENSION_SHIFT;
						header.Copyright = (mpeg_header & MPEG_COPYRIGHT ? 1 : 0);
						header.Original = (mpeg_header & MPEG_ORIGINAL ? 1 : 0);
						header.Emphasis = (mpeg_header & MPEG_EMPHASIS) >> MPEG_EMPHASIS_SHIFT;

						Console.putln("Header: ", mpeg_header & MPEG_SYNC_BITS, "\n",
								"ID: ", header.ID, "\n",
								"Layer: ", header.Layer, "\n",
								"Protected: ", header.Protected, "\n",
								"BitrateIndex: ", header.BitrateIndex, "\n",
								"SamplingFrequency: ", header.SamplingFrequency, "\n",
								"Padding: ", header.Padding, "\n",
								"Private: ", header.Private, "\n",
								"Mode: ", header.Mode, "\n",
								"ModeExtension: ", header.ModeExtension, "\n",
								"Copyright: ", header.Copyright, "\n",
								"Original: ", header.Original, "\n",
								"Emphasis: ", header.Emphasis);


						// Calculate the length of the Audio Data
						audioDataLength = cast(uint)(144 * (cast(double)bitRates[header.BitrateIndex] / cast(double)samplingFrequencies[header.SamplingFrequency]));
						if (header.Padding) { audioDataLength++; }

						// subtract the size of the header
						audioDataLength -= 4;

						// allocate the buffer
						audioData = new ubyte[audioDataLength];

					//	writeln("Audio Data Length: ", audioDataLength);
					//	writeln("curByte: ", audioData.ptr);


						// set the format of the wave buffer

						if (header.SamplingFrequency == 0) {
							// 44.1 kHz
							wf.samplesPerSecond = 44100;
						}
						else if (header.SamplingFrequency == 1) {
							// 48 kHz
							wf.samplesPerSecond = 48000;
						}
						else {
							// 32 kHz
							wf.samplesPerSecond = 32000;
						}

						wf.compressionType = 1;

						switch(header.Mode) {
							case MPEG_MODE_STEREO:
							case MPEG_MODE_DUAL_CHANNEL:
								wf.numChannels = 2;
								break;

							case MPEG_MODE_SINGLE_CHANNEL:
								wf.numChannels = 1;
								break;

							case MPEG_MODE_JOINT_STEREO:
								wf.numChannels = 2;
								break;

							default: // impossible!
								return StreamData.Invalid;
						}


						wf.averageBytesPerSecond = wf.samplesPerSecond * 2 * wf.numChannels;
						wf.blockAlign = 2 * wf.numChannels;
						wf.bitsPerSample = 16;

						// set the wavelet's audio format
						if (toBuffer !is null) {
							toBuffer.setAudioFormat(wf);
							bufferTime = toBuffer.time;
						}

						if (header.Protected == 0) {
							decoderState = MP2_READ_CRC;
						}
						else {
							decoderState = MP2_READ_AUDIO_DATA;
						}

						if (!accepted) {
							if (toBuffer !is null) {
								if (toBuffer.length() != bufferSize) {
									Console.putln("resize ", bufferSize, " from ", toBuffer.length());
									toBuffer.resize(bufferSize);
								}
								toBuffer.rewind();
							}

							if (toBuffer is null && isSeek == false) {
								return StreamData.Accepted;
							}
						}
						
						accepted = true;

						continue;
					}
					else {
//						Console.putln("cur test ", mpeg_header & MPEG_SYNC_BITS, " @ ", stream.position - 4);
						ubyte curByte;
						if (!stream.read(curByte)) {
							return StreamData.Required;
						}

						mpeg_header <<= 8;
						mpeg_header |= (cast(uint)curByte);
					}

					continue;

				case MP2_READ_CRC:

					if (!stream.read(crc)) {
						return StreamData.Required;
					}

					decoderState = MP2_READ_AUDIO_DATA;


					// *** falls through *** //

				case MP2_READ_AUDIO_DATA:

					// read in the audio data to a buffer
					// then use that buffer to gather the useful information

					if (isSeek) {
						// skip over audio data
						if (!stream.skip(audioData.length)) {
							return StreamData.Required;
						}

						switch(header.Mode) {
							case MPEG_MODE_STEREO:
							case MPEG_MODE_DUAL_CHANNEL:
								channels = 2;
								break;

							case MPEG_MODE_SINGLE_CHANNEL:
								channels = 1;
								break;

							case MPEG_MODE_JOINT_STEREO:
								break;

							default: // impossible!
								return StreamData.Invalid;
						}

						// do not decode
						samplesLeft -= (12*32*3*channels);

						if (samplesLeft <= 0) {
							decoderState = MP2_BUFFER_AUDIO;
							curTime += bufferTime;
							curTime.toString();
						}
						else {
							decoderState = MP2_READ_HEADER;
						}
						continue;
					}

					if (!stream.read(audioData)) {
						return StreamData.Required;
					}
//					toBuffer.setAudioFormat(wf);

					//writeln("curByte: ", audioData.length);
					curByte = audioData.ptr;
					curPos = 0;

					switch(header.Mode) {
						case MPEG_MODE_STEREO:
						case MPEG_MODE_DUAL_CHANNEL:
							channels = 2;
							decoderState = MP2_READ_AUDIO_DATA_SINGLE_CHANNEL;
							break;

						case MPEG_MODE_SINGLE_CHANNEL:
							channels = 1;
							decoderState = MP2_READ_AUDIO_DATA_SINGLE_CHANNEL;
							break;

						case MPEG_MODE_JOINT_STEREO:
							decoderState = MP2_READ_AUDIO_DATA_JOINT_STEREO;
							break;

						default: // impossible!
							return StreamData.Invalid;
					}

					continue;

				case MP2_READ_AUDIO_DATA_SINGLE_CHANNEL:

					// read in allocation bits

					// Determine which allocation table to use
					//   depending on the sample frequency and bitrate

					// Table A:
					//    48 kHz 	: 56, 64, 80, 96, 112, 128, 160, 192 kbits/s
					//    44.1		: 56, 64, 80
					//    32		: 56, 64, 80

					// Table B:
					//    48		: N/A
					//    44.1		: 96, 112, 128, 160, 192
					//    32		: 96, 112, 128, 160, 192

					// Table C:
					//    48		: 32, 48
					//    44.1		: 32, 48
					//    32		: N/A

					// Table D:
					//    48		: N/A
					//    44.1		: N/A
					//    32		: 32, 48

					uint tableType;
					uint sblimit;

					if (header.SamplingFrequency == 0) {
						// 44.1 kHz

						if (header.BitrateIndex >= 3 && header.BitrateIndex <= 5) {
							// TABLE A
							tableType = 0;
							sblimit = 27;
						}
						else if (header.BitrateIndex >= 6) {
							// TABLE B
							tableType = 0;
							sblimit = 30;
						}
						else {
							// TABLE C
							tableType = 1;
							sblimit = 8;
						}
					}
					else if (header.SamplingFrequency == 1) {
						// 48 kHz

						if (header.BitrateIndex >= 3) {
							// TABLE A
							tableType = 0;
							sblimit = 27;
						}
						else {
							// TABLE C
							tableType = 1;
							sblimit = 8;
						}
					}
					else {
						// 32 kHz

						if (header.BitrateIndex >= 3 && header.BitrateIndex <= 5) {
							// TABLE A
							tableType = 0;
							sblimit = 27;
						}
						else if (header.BitrateIndex >= 6) {
							// TABLE B
							tableType = 0;
							sblimit = 30;
						}
						else {
							// TABLE D
							tableType = 1;
							sblimit = 12;
						}
					}

					uint sb, channel;

					if (tableType == 0) {
						// TABLE A/B

						// length: 4 bits
						uint idx;

						for ( ; sb < 3; sb++) {
							for (channel=0; channel<channels; channel++) {
								idx = readBits(4);
								allocClass[channel][sb] = cast(QuantizationClass*)&allocationToQuantA1[idx];
							}
						}

						for ( ; sb < 11; sb++) {
							for (channel=0; channel<channels; channel++) {
								idx = readBits(4);
								allocClass[channel][sb] = cast(QuantizationClass*)&allocationToQuantA2[idx];
							}
						}

						for ( ; sb < 23; sb++) {
							for (channel=0; channel<channels; channel++) {
								idx = readBits(3);
								allocClass[channel][sb] = cast(QuantizationClass*)&allocationToQuantA3[idx];
							}
						}

						for ( ; sb < sblimit; sb++) {
							for (channel=0; channel<channels; channel++)
							{
								idx = readBits(2);
								allocClass[channel][sb] = cast(QuantizationClass*)&allocationToQuantA4[idx];
							}
						}
					}
					else {
						// TABLE C/D

						uint idx;

						for ( ; sb < 2; sb++) {
							for (channel=0; channel<channels; channel++) {
								idx = readBits(4);
								allocClass[channel][sb] = cast(QuantizationClass*)&allocationToQuantC1[idx];
							}
						}

						for ( ; sb < sblimit; sb++) {
							for (channel=0; channel<channels; channel++) {
								idx = readBits(3);
								allocClass[channel][sb] = cast(QuantizationClass*)&allocationToQuantC1[idx];
							}
						}
					}

					// Read Scalefactor Selection Information

					for (sb=0; sb<sblimit; sb++) {
						for (channel=0; channel<channels; channel++) {
							if (allocClass[channel][sb].numberOfSteps!=0) {
								scfsi[channel][sb] = readBits(2);
							}
						}
					}

					// Read Scalefactor Indices

					for (sb=0; sb<sblimit; sb++) {
						for (channel=0; channel<channels; channel++) {
							if (allocClass[channel][sb].numberOfSteps!=0) {
								if (scfsi[channel][sb]==0) {
									scalefactor[channel][0][sb] = readBits(6); 	// 6	bits	uimsbf
									scalefactor[channel][1][sb] = readBits(6);	// 6	bits	uimsbf
									scalefactor[channel][2][sb] = readBits(6);  // 6	bits	uimsbf
								}
								else if ((scfsi[channel][sb]==1) || (scfsi[channel][sb]==3)) {
									scalefactor[channel][0][sb] = readBits(6); 	// 6	bits	uimsbf
									scalefactor[channel][2][sb] = readBits(6);	// 6	bits	uimsbf

									// scale factors are paired differently:
									if (scfsi[channel][sb] == 1) {
										scalefactor[channel][1][sb] = scalefactor[channel][0][sb];
									}
									else {
										scalefactor[channel][1][sb] = scalefactor[channel][2][sb];
									}
								}
								else if (scfsi[channel][sb]==2) {
									scalefactor[channel][0][sb] = readBits(6);  // 6	bits	uimsbf
									scalefactor[channel][1][sb] = scalefactor[channel][0][sb];
									scalefactor[channel][2][sb] = scalefactor[channel][0][sb];
								}
							}
							else {
								scalefactor[channel][0][sb] = 63;
								scalefactor[channel][1][sb] = 63;
								scalefactor[channel][2][sb] = 63;
							}
						}
					}

					uint gr, s;

					for (gr=0; gr<12; gr++) {
						for (sb=0; sb<sblimit; sb++) {
							for (channel=0; channel<channels; channel++) {
								if (allocClass[channel][sb].numberOfSteps!=0) {
									if (allocClass[channel][sb].grouping) {
										samplecode = readBits(allocClass[channel][sb].bitsPerCodeword);	// 5..10	bits	uimsbf
											//writeln(samplecode[sb][gr], " bit");
										assert((allocClass[channel][sb].bitsPerCodeword > 4) && (allocClass[channel][sb].bitsPerCodeword < 11));

										// ungroup

										for (s=0; s<3; s++) {
											sample[channel][s][sb] = samplecode % allocClass[channel][sb].numberOfSteps;
											samplecode /= allocClass[channel][sb].numberOfSteps;

											// requantize
										}
									}
									else {
										for (s=0; s<3; s++) {
											sample[channel][s][sb] = readBits(allocClass[channel][sb].bitsPerCodeword); // 2..16	bits	uimsbf
												//writeln(sample[sb][s], " bit");
											assert((allocClass[channel][sb].bitsPerCodeword > 1) && (allocClass[channel][sb].bitsPerCodeword < 17));

										}
									}
								}
								else {
									sample[channel][0][sb] = 0;
									sample[channel][1][sb] = 0;
									sample[channel][2][sb] = 0;
								}
							}
						}

						for ( ; sb<32; sb++) {
							for (s=0; s<3; s++) {
								quantSample[0][s][sb] = 0.0;
								quantSample[1][s][sb] = 0.0;
							}
						}

						// Now, pass these subband samples to
						// the Synthesis Subband Filter

						for ( sb =0; sb<sblimit; sb++) {
							for (channel=0; channel<channels; channel++) {
								for (s=0; s<3; s++) {
									// dequantize
									uint x = 0;

									while ((1<<x) < allocClass[channel][sb].numberOfSteps)
										{ x++; }

									if ((sample[channel][s][sb] >> (x-1)) == 1) {
										quantSample[channel][s][sb] = 0.0;
									}
									else {
										quantSample[channel][s][sb] = -1.0;
									}

									if (x > 0) {
										quantSample[channel][s][sb] += cast(double)(sample[channel][s][sb] & bitFills[x]) /
																			cast(double)(1<<x-1);
									}

									// s'' = ( s''' + D ) * C
									quantSample[channel][s][sb] += allocClass[channel][sb].D;
									quantSample[channel][s][sb] *= allocClass[channel][sb].C;

									// rescale
									// s' = factor * s''

									quantSample[channel][s][sb] *= scaleFactors[scalefactor[channel][gr >> 2][sb]];

									//printf("[%d][%d][%d] = %f\n", channel,s,sb, quantSample[channel][s][sb]);
								}
							}
						}

						double sum;

						uint i,k,j;

						int clip;

						for (s=0; s<3; s++) {
							long foo;

							double* bufOffsetPtr;
							double* bufOffsetPtr2;

							if (channels == 1) {
								channel = 0;

							    bufOffset[channel] = (bufOffset[channel] - 64) & 0x3ff;
							    bufOffsetPtr = cast(double*)&BB[channel][bufOffset[channel]];

								for (i=0; i<64; i++) {
									sum = 0;
									for (k=0; k<32; k++) {
										sum += quantSample[channel][s][k] * nCoefficients[i][k];
									}
									bufOffsetPtr[i] = sum;
								}

								for (j=0; j<32; j++) {
									sum = 0;
									for (i=0; i<16; i++) {
										k = j + (i << 5);

										sum += windowCoefficients[k] * BB[channel][( (k + ( ((i+1)>>1) << 6) ) + bufOffset[channel]) & 0x3ff];
									}

							        if(sum > 0) {
										foo = cast(long)(sum * cast(double)32768 + cast(double)0.5);
							        }
							        else {
										foo = cast(long)(sum * cast(double)32768 - cast(double)0.5);
							        }

									if (foo >= cast(long)32768) {
										toBuffer.write(cast(short)(32768-1));
										//++clip;
									}
									else if (foo < cast(long)-32768) {
										toBuffer.write(cast(short)(-32768));
										//++clip;
									}
									else {
										toBuffer.write(cast(short)foo);
									}

									//printf("%d\n", foo);
								}
							}
							else {
								// INTERLEAVE CHANNELS!

							    bufOffset[0] = (bufOffset[0] - 64) & 0x3ff;
							    bufOffsetPtr = cast(double*)&BB[0][bufOffset[0]];

							    bufOffset[1] = (bufOffset[1] - 64) & 0x3ff;
							    bufOffsetPtr2 = cast(double*)&BB[1][bufOffset[1]];

							    double sum2;

								for (i=0; i<64; i++) {
									sum = 0;
									sum2 = 0;
									for (k=0; k<32; k++) {
										sum += quantSample[0][s][k] * nCoefficients[i][k];
										sum2 += quantSample[1][s][k] * nCoefficients[i][k];
									}
									bufOffsetPtr[i] = sum;
									bufOffsetPtr2[i] = sum2;
								}

								for (j=0; j<32; j++) {
									sum = 0;
									sum2 = 0;
									for (i=0; i<16; i++) {
										k = j + (i << 5);

										sum += windowCoefficients[k] * BB[0][( (k + ( ((i+1)>>1) << 6) ) + bufOffset[0]) & 0x3ff];
										sum2 += windowCoefficients[k] * BB[1][( (k + ( ((i+1)>>1) << 6) ) + bufOffset[1]) & 0x3ff];
									}

							        if(sum > 0) {
										foo = cast(long)(sum * cast(double)32768 + cast(double)0.5);
							        }
							        else {
										foo = cast(long)(sum * cast(double)32768 - cast(double)0.5);
							        }

									if (foo >= cast(long)32768) {
										toBuffer.write(cast(short)(32768-1));
										//++clip;
									}
									else if (foo < cast(long)-32768) {
										toBuffer.write(cast(short)(-32768));
										//++clip;
									}
									else {
										toBuffer.write(cast(short)foo);
									}

							        if(sum2 > 0) {
										foo = cast(long)(sum2 * cast(double)32768 + cast(double)0.5);
							        }
							        else {
										foo = cast(long)(sum2 * cast(double)32768 - cast(double)0.5);
							        }

									if (foo >= cast(long)32768) {
										toBuffer.write(cast(short)(32768-1));
										//++clip;
									}
									else if (foo < cast(long)-32768) {
										toBuffer.write(cast(short)(-32768));
										//++clip;
									}
									else {
										toBuffer.write(cast(short)foo);
									}
								}
							}
						}
					}

					samplesLeft -= (12*32*3*channels);

					if (samplesLeft <= 0) {
						decoderState = MP2_BUFFER_AUDIO;
						curTime += bufferTime;
							curTime.toString();
						return StreamData.Accepted;
					}

					decoderState = MP2_READ_HEADER;

					continue;

				case MP2_READ_AUDIO_DATA_DUAL_CHANNEL:

					// read in allocation bits

					// Determine which allocation table to use
					//   depending on the sample frequency and bitrate

					// Table A:
					//    48 kHz 	: 56, 64, 80, 96, 112, 128, 160, 192 kbits/s
					//    44.1		: 56, 64, 80
					//    32		: 56, 64, 80

					// Table B:
					//    48		: N/A
					//    44.1		: 96, 112, 128, 160, 192
					//    32		: 96, 112, 128, 160, 192

					// Table C:
					//    48		: 32, 48
					//    44.1		: 32, 48
					//    32		: N/A

					// Table D:
					//    48		: N/A
					//    44.1		: N/A
					//    32		: 32, 48

					uint tableType;
					uint sblimit;

					if (header.SamplingFrequency == 0) {
						// 44.1 kHz

						if (header.BitrateIndex >= 3 && header.BitrateIndex <= 5) {
							// TABLE A
							tableType = 0;
							sblimit = 27;
						}
						else if (header.BitrateIndex >= 6) {
							// TABLE B
							tableType = 0;
							sblimit = 30;
						}
						else {
							// TABLE C
							tableType = 1;
							sblimit = 8;
						}
					}
					else if (header.SamplingFrequency == 1) {
						// 48 kHz

						if (header.BitrateIndex >= 3) {
							// TABLE A
							tableType = 0;
							sblimit = 27;
						}
						else {
							// TABLE C
							tableType = 1;
							sblimit = 8;
						}
					}
					else {
						// 32 kHz

						if (header.BitrateIndex >= 3 && header.BitrateIndex <= 5) {
							// TABLE A
							tableType = 0;
							sblimit = 27;
						}
						else if (header.BitrateIndex >= 6) {
							// TABLE B
							tableType = 0;
							sblimit = 30;
						}
						else {
							// TABLE D
							tableType = 1;
							sblimit = 12;
						}
					}

					uint sb;

					if (tableType == 0) {
						// TABLE A/B

						// length: 4 bits
						uint idx;

						for ( ; sb < 3; sb++) {
							idx = readBits(4);
							allocClass[0][sb] = cast(QuantizationClass*)&allocationToQuantA1[idx];
							idx = readBits(4);
							allocClass[1][sb] = cast(QuantizationClass*)&allocationToQuantA1[idx];
						}

						for ( ; sb < 11; sb++) {
							idx = readBits(4);
							allocClass[0][sb] = cast(QuantizationClass*)&allocationToQuantA2[idx];
							idx = readBits(4);
							allocClass[1][sb] = cast(QuantizationClass*)&allocationToQuantA2[idx];
						}

						for ( ; sb < 23; sb++) {
							idx = readBits(3);
							allocClass[0][sb] = cast(QuantizationClass*)&allocationToQuantA3[idx];
							idx = readBits(3);
							allocClass[1][sb] = cast(QuantizationClass*)&allocationToQuantA3[idx];
						}

						for ( ; sb < sblimit; sb++) {
							idx = readBits(2);
							allocClass[0][sb] = cast(QuantizationClass*)&allocationToQuantA4[idx];
							idx = readBits(2);
							allocClass[1][sb] = cast(QuantizationClass*)&allocationToQuantA4[idx];
						}
					}
					else {
						// TABLE C/D

						uint idx;

						for ( ; sb < 2; sb++) {
							idx = readBits(4);
							allocClass[0][sb] = cast(QuantizationClass*)&allocationToQuantC1[idx];
							idx = readBits(4);
							allocClass[1][sb] = cast(QuantizationClass*)&allocationToQuantC1[idx];

						}

						for ( ; sb < sblimit; sb++) {
							idx = readBits(3);
							allocClass[0][sb] = cast(QuantizationClass*)&allocationToQuantC1[idx];
							idx = readBits(3);
							allocClass[1][sb] = cast(QuantizationClass*)&allocationToQuantC1[idx];
						}
					}

					// Read Scalefactor Selection Information

					for (sb=0; sb<sblimit; sb++) {
						if (allocClass[0][sb].numberOfSteps!=0) {
							scfsi[0][sb] = readBits(2);
						}

						if (allocClass[1][sb].numberOfSteps!=0) {
							scfsi[1][sb] = readBits(2);
						}
					}

					// Read Scalefactor Indices

					for (sb=0; sb<sblimit; sb++) {
						if (allocClass[0][sb].numberOfSteps!=0) {
							if (scfsi[0][sb]==0) {
								scalefactor[0][0][sb] = readBits(6); 	// 6	bits	uimsbf
								scalefactor[0][1][sb] = readBits(6);	// 6	bits	uimsbf
								scalefactor[0][2][sb] = readBits(6);  // 6	bits	uimsbf
							}
							else if ((scfsi[0][sb]==1) || (scfsi[0][sb]==3)) {
								scalefactor[0][0][sb] = readBits(6); 	// 6	bits	uimsbf
								scalefactor[0][2][sb] = readBits(6);	// 6	bits	uimsbf

								// scale factors are paired differently:
								if (scfsi[0][sb] == 1) {
									scalefactor[0][1][sb] = scalefactor[0][0][sb];
								}
								else {
									scalefactor[0][1][sb] = scalefactor[0][2][sb];
								}
							}
							else if (scfsi[0][sb]==2) {
								scalefactor[0][0][sb] = readBits(6);  // 6	bits	uimsbf
								scalefactor[0][1][sb] = scalefactor[0][0][sb];
								scalefactor[0][2][sb] = scalefactor[0][0][sb];
							}
						}
						else {
							scalefactor[0][0][sb] = 63;
							scalefactor[0][1][sb] = 63;
							scalefactor[0][2][sb] = 63;
						}

						if (allocClass[1][sb].numberOfSteps!=0) {
							if (scfsi[1][sb]==0) {
								scalefactor[1][0][sb] = readBits(6); 	// 6	bits	uimsbf
								scalefactor[1][1][sb] = readBits(6);	// 6	bits	uimsbf
								scalefactor[1][2][sb] = readBits(6);  // 6	bits	uimsbf
							}
							else if ((scfsi[1][sb]==1) || (scfsi[1][sb]==3)) {
								scalefactor[1][0][sb] = readBits(6); 	// 6	bits	uimsbf
								scalefactor[1][2][sb] = readBits(6);	// 6	bits	uimsbf

								// scale factors are paired differently:
								if (scfsi[1][sb] == 1) {
									scalefactor[1][1][sb] = scalefactor[1][0][sb];
								}
								else {
									scalefactor[1][1][sb] = scalefactor[1][2][sb];
								}
							}
							else if (scfsi[1][sb]==2) {
								scalefactor[1][0][sb] = readBits(6);  // 6	bits	uimsbf
								scalefactor[1][1][sb] = scalefactor[1][0][sb];
								scalefactor[1][2][sb] = scalefactor[1][0][sb];
							}
						}
						else {
							scalefactor[1][0][sb] = 63;
							scalefactor[1][1][sb] = 63;
							scalefactor[1][2][sb] = 63;
						}
					}

					uint gr, s, base;

					for (gr=0, base=0; gr<12; gr++, base+=3) {
						for (sb=0; sb<sblimit; sb++) {
							if (allocClass[0][sb].numberOfSteps!=0) {
								if (allocClass[0][sb].grouping) {
									samplecode = readBits(allocClass[0][sb].bitsPerCodeword);	// 5..10	bits	uimsbf
										//writeln(samplecode, "@ bit");
									assert((allocClass[0][sb].bitsPerCodeword > 4) && (allocClass[0][sb].bitsPerCodeword < 11));

									// ungroup

									for (s=0; s<3; s++) {
										sample[0][base + s][sb] = samplecode % allocClass[0][sb].numberOfSteps;
										samplecode /= allocClass[0][sb].numberOfSteps;

										// requantize
									}
								}
								else {
									for (s=0; s<3; s++) {
										sample[0][base + s][sb] = readBits(allocClass[0][sb].bitsPerCodeword); // 2..16	bits	uimsbf
											//writeln(sample[0][s][sb], "! bit ", allocClass[0][sb].bitsPerCodeword);
										assert((allocClass[0][sb].bitsPerCodeword > 1) && (allocClass[0][sb].bitsPerCodeword < 17));

									}
								}
							}
							else {
								sample[0][base + 0][sb] = 0;
								sample[0][base + 1][sb] = 0;
								sample[0][base + 2][sb] = 0;
							}

							if (allocClass[1][sb].numberOfSteps!=0) {
								if (allocClass[1][sb].grouping) {
									samplecode = readBits(allocClass[1][sb].bitsPerCodeword);	// 5..10	bits	uimsbf
										//writeln(samplecode, "+ bit");
									assert((allocClass[1][sb].bitsPerCodeword > 4) && (allocClass[1][sb].bitsPerCodeword < 11));

									// ungroup

									for (s=0; s<3; s++) {
										sample[1][base + s][sb] = samplecode % allocClass[1][sb].numberOfSteps;
										samplecode /= allocClass[1][sb].numberOfSteps;

										// requantize
									}
								}
								else {
									for (s=0; s<3; s++) {
										sample[1][base + s][sb] = readBits(allocClass[1][sb].bitsPerCodeword); // 2..16	bits	uimsbf
											//writeln(sample[1][s][sb], "- bit");
										assert((allocClass[1][sb].bitsPerCodeword > 1) && (allocClass[1][sb].bitsPerCodeword < 17));

									}
								}
							}
							else {
								sample[1][base + 0][sb] = 0;
								sample[1][base + 1][sb] = 0;
								sample[1][base + 2][sb] = 0;
							}
						}

						for ( ; sb<32; sb++) {
							for (s=0; s<3; s++) {
								quantSample[0][base + s][sb] = 0.0;
								quantSample[1][base + s][sb] = 0.0;
							}
						}

						// Now, pass these subband samples to
						// the Synthesis Subband Filter

						for ( sb =0; sb<sblimit; sb++) {
							for (s=0; s<3; s++) {
								// dequantize
								uint x = 0;

								while ((1<<x) < allocClass[0][sb].numberOfSteps) {
									x++;
								}

								if ((sample[0][base + s][sb] >> (x-1)) == 1) {
									quantSample[0][base + s][sb] = 0.0;
								}
								else
								{
									quantSample[0][base + s][sb] = -1.0;
								}

								if (x > 0) {
									quantSample[0][base + s][sb] += cast(double)(sample[0][base + s][sb] & bitFills[x])
										/ cast(double)(1<<x-1);
								}

								// s'' = ( s''' + D ) * C
								quantSample[0][base + s][sb] += allocClass[0][sb].D;
								quantSample[0][base + s][sb] *= allocClass[0][sb].C;

								// rescale
								// s' = factor * s''

								quantSample[0][base + s][sb] *= scaleFactors[scalefactor[0][gr>>2][sb]];

								//printf("sample = [%d][%d][%d] = %f\n", 0, s, sb, quantSample[0][s][sb]);


								x=0;

								while ((1<<x) < allocClass[1][sb].numberOfSteps) {
									x++;
								}

								if ((sample[1][base + s][sb] >> (x-1)) == 1) {
									quantSample[1][base + s][sb] = 0.0;
								}
								else {
									quantSample[1][base + s][sb] = -1.0;
								}

								if (x > 0) {
									quantSample[1][base + s][sb] += cast(double)(sample[1][base + s][sb] & bitFills[x]) /
																		cast(double)(1<<x-1);
								}

								// s'' = ( s''' + D ) * C
								quantSample[1][base + s][sb] += allocClass[1][sb].D;
								quantSample[1][base + s][sb] *= allocClass[1][sb].C;

								// rescale
								// s' = factor * s''

								quantSample[1][base + s][sb] *= scaleFactors[scalefactor[1][gr>>2][sb]];

								//printf("sample = [%d][%d][%d] = %f\n", 1, s, sb, quantSample[1][s][sb]);
							}
						}

						double sum;

						uint i,k,j;

						int clip;

						for (s=0; s<3; s++) {
							for (uint channel = 0;channel<2;channel++) {
								long foo;
								static int bufOffset[2] = [64,64];

								// initialize the array to zero
								typedef double zerodouble = 0.0;

								static zerodouble BB[2][2*512];

								double* bufOffsetPtr;

								bufOffset[channel] = (bufOffset[channel] - 64) & 0x3ff;
								bufOffsetPtr = cast(double*)&BB[channel][bufOffset[channel]];

								for (i=0; i<64; i++) {
									sum = 0;
									for (k=0; k<32; k++) {
										sum += quantSample[channel][base + s][k] * nCoefficients[i][k];
									}
									bufOffsetPtr[i] = sum;
								}


								for (j=0; j<32; j++) {
									sum = 0;
									for (i=0; i<16; i++) {
										k = j + (i << 5);

										sum += windowCoefficients[k] * BB[channel][( (k + ( ((i+1)>>1) << 6) ) + bufOffset[channel]) & 0x3ff];
									}

							        if(sum > 0) {
										foo = cast(long)(sum * cast(double)32768 + cast(double)0.5);
							        }
							        else {
										foo = cast(long)(sum * cast(double)32768 - cast(double)0.5);
							        }

									if (foo >= cast(long)32768) {
										toBuffer.write(cast(short)(32768-1));
										//++clip;
									}
									else if (foo < cast(long)-32768) {
										toBuffer.write(cast(short)(-32768));
										//++clip;
									}
									else {
										toBuffer.write(cast(short)foo);
									}

									//writeln(foo);
								}
							}
						}
					}

					samplesLeft -= (12*32*3*2);

					if (samplesLeft <= 0) {
						decoderState = MP2_BUFFER_AUDIO;
						curTime += bufferTime;
						return StreamData.Accepted;
					}

					decoderState = MP2_READ_HEADER;

					continue;

				case MP2_READ_AUDIO_DATA_JOINT_STEREO:

					continue;

					// -- Default for corrupt files -- //

				default:
					// invalid state
					break;
			}
			break;
		}
		return StreamData.Invalid;
	}

	uint readBits(uint bits) {
		// read a byte, read bits, whatever necessary to get the value
		//writeln("reading, # bits:", bits, " curbyte:", *curByte);

		uint curvalue;
		uint value = 0;

		uint mask;
		uint maskbits;

		int shift;

		if (curByte >= audioData.ptr + audioData.length) {
			// We have consumed everything in our buffer
			return 0;
		}

		for (;;) {
			if (bits == 0) { return value; }

			if (bits > 8) {
				maskbits = 8;
			}
			else {
				maskbits = bits;
			}
			//writeln("curpos:", curPos, " for bits:", bits, " maskbits:", maskbits);

			curvalue = ((*curByte) & (byteMasks[maskbits][curPos]));

			shift = ((8-cast(int)curPos) - cast(int)bits);

			if (shift > 0) {
				curvalue >>= shift;
			}
			else if (shift < 0) {
				curvalue <<= -shift;
			}

			//writeln("has curvalue:", curvalue);

			value |= curvalue;

			//writeln("has value:", value);

			curPos += maskbits;

			if (curPos >= 8) {
				bits -= (8 - curPos + maskbits);
				curPos = 0;
				curByte++;

				if (curByte >= audioData.ptr + audioData.length) {
					// We have consumed everything in our buffer
					return 0;
				}

				//writeln("CURBYTE ** ", *curByte, " ** ");
			}
			else {
				break;
			}
		}
		return value;
	}

	StreamData seek(Stream stream, AudioFormat wf, AudioInfo wi, ref Time amount) {
		if (decoderState == 0) {
			// not inited?
			return StreamData.Invalid;
		}

		if (amount == curTime) {
			Console.putln("ON TIME");
			return StreamData.Accepted;
		}

		if (amount > curTime) {
			Console.putln("WE NEED TO GO AHEAD");
			// good!
			// simply find the section we need to be
			// we are buffering 2 seconds...
			toSeek = amount;
			isSeekBack = false;
			isSeek = true;
			StreamData ret = decode(stream, null, wi);
			if (ret == StreamData.Required) { return ret; }

			amount -= curTime;
			amount.toString();
			return ret;
		}
		else {
			Console.putln("WE NEED TO FALL BEHIND");
			// for wave files, this is not altogether a bad thing
			// for other types of files, it might be
			// mp3 can be variable, and would require a seek from the
			// beginning or maintaining a cache of some sort.
			if (!stream.rewind(cast(ulong)(stream.position - cast(long)posOfFirstFrame)))
			{
				return StreamData.Required;
			}

			toSeek = amount;
			isSeekBack = false;
			isSeek = true;

			curTime = Time.init;

			StreamData ret =  decode(stream, null, wi);
			if (ret == StreamData.Required) { return ret; }

			amount -= curTime;
			amount.toString();
			return ret;
		}
	}

	Time length(Stream stream, ref AudioFormat wf, ref AudioInfo wi) {
		Time tme = Time.init;
		return tme;
	}

	Time lengthQuick(Stream stream, ref AudioFormat wf, ref AudioInfo wi) {
		Time tme = Time.init;
		return tme;
	}
<<<<<<< HEAD:decoders/audio/mp2.d
=======

>>>>>>> 7168ba66303a9911bd72a3752dc0134777b0ea6e:decoders/audio/mp2.d
}
