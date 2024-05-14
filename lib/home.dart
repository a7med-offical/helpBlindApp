import 'dart:io';
import 'dart:ui';
import 'package:animated_text_kit/animated_text_kit.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:text_to_speech/text_to_speech.dart';

class textRS extends StatefulWidget {
  @override
  _textRSState createState() => _textRSState();
}

class _textRSState extends State<textRS> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  TextToSpeech tts = TextToSpeech();
  final String defaultLanguage = 'en-US';

  String text = '';
  double volume = 1;
  double rate = 1.0;
  double pitch = 1.0;

  String? language;
  String? languageCode;
  List<String> languages = <String>[];
  List<String> languageCodes = <String>[];
  String? voice;

  TextEditingController textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();

    textEditingController.text = text;
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      initLanguages();
    });
  }

  Future<void> initLanguages() async {
    languageCodes = await tts.getLanguages();

    final List<String>? displayLanguages = await tts.getDisplayLanguages();
    if (displayLanguages == null) {
      return;
    }

    languages.clear();
    for (final dynamic lang in displayLanguages) {
      languages.add(lang as String);
    }

    final String? defaultLangCode = await tts.getDefaultLanguage();
    if (defaultLangCode != null && languageCodes.contains(defaultLangCode)) {
      languageCode = defaultLangCode;
    } else {
      languageCode = defaultLanguage;
    }
    language = await tts.getDisplayLanguageByCode(languageCode!);

    /// get voice
    voice = await getVoiceByLang(languageCode!);

    if (mounted) {
      setState(() {});
    }
  }

  Future<String?> getVoiceByLang(String lang) async {
    final List<String>? voices = await tts.getVoiceByLang(languageCode!);
    if (voices != null && voices.isNotEmpty) {
      return voices.first;
    }
    return null;
  }

  XFile? pickedImage;
  bool scanning = false;

  final ImagePicker _imagePicker = ImagePicker();

  getImage(ImageSource ourSource) async {
    XFile? result = await _imagePicker.pickImage(source: ourSource);

    if (result != null) {
      setState(() {
        pickedImage = result;
      });

      performTextLabelling();
    }
  }

  performTextLabelling() async {
    if (!mounted) return;
    setState(() {
      text = '';
      scanning = true;
    });
    try {
      final inputImage = InputImage.fromFilePath(pickedImage!.path);

      final imageLabeler = GoogleMlKit.vision.imageLabeler();

      final List labels = await imageLabeler.processImage(inputImage);

      for (var label in labels) {
        text +=
            '${label.label} (${(label.confidence * 100).toStringAsFixed(2)}%)\n';
      }

      setState(() {
        scanning = false;
      });

      imageLabeler.close();
    } catch (e) {
      print('Error during text recognition: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 10, 23, 35),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        leading: Icon(Icons.ac_unit_outlined),
        title: const Text(
          'Helper App',
        ),
      ),
      body: ListView(
        shrinkWrap: true,
        children: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 40),
            height: 1,
            color: Colors.white,
          ),
          pickedImage == null
              ? Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(10)),
                    height: 280,
                    child: const Center(
                      child: Text(
                        'No Image Selected',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Image.file(
                  File(pickedImage!.path),
                  height: 280,
                )),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                onPressed: () {
                  getImage(ImageSource.gallery);
                },
                icon: const Icon(
                  Icons.photo,
                  color: Colors.black,
                ),
                label: const Text(
                  'Gallery',
                  style: TextStyle(color: Colors.black),
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                onPressed: () {
                  getImage(
                    ImageSource.camera,
                  );
                },
                icon: const Icon(
                  Icons.camera_alt,
                  color: Colors.black,
                ),
                label:
                    const Text('Camera', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Center(child: Text('Recognized Image:')),
          const SizedBox(height: 30),
          scanning
              ?  Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                      child: SpinKitThreeBounce(
                    color: Colors.black,
                    size: 20,
                  )),
                )
              : Center(
                  child: AnimatedTextKit(
                      isRepeatingAnimation: false,
                      animatedTexts: [
                        TypewriterAnimatedText(text,
                            textAlign: TextAlign.center,
                            textStyle: const TextStyle(fontSize: 20)),
                      ]),
                ),
          const SizedBox(
            height: 10,
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Text('Language'),
                        const SizedBox(
                          width: 20,
                        ),
                        DropdownButton<String>(
                          value: language,
                          icon: const Icon(Icons.arrow_downward),
                          iconSize: 24,
                          elevation: 16,
                          style: const TextStyle(color: Colors.white),
                          underline: Container(
                            height: 2,
                            color: Colors.deepPurpleAccent,
                          ),
                          onChanged: (String? newValue) async {
                            languageCode =
                                await tts.getLanguageCodeByName(newValue!);
                            voice = await getVoiceByLang(languageCode!);
                            setState(() {
                              language = newValue;
                            });
                          },
                          items: languages
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Row(
                      children: <Widget>[
                        const Text('Voice'),
                        const SizedBox(
                          width: 20,
                        ),
                        Text(voice ?? '-'),
                      ],
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.only(right: 10),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber),
                              child: const Text(
                                'Stop',
                                style: TextStyle(color: Colors.black),
                              ),
                              onPressed: () {
                                tts.stop();
                              },
                            ),
                          ),
                        ),
                        if (supportPause)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.only(right: 10),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber),
                                child: const Text(
                                  'Pause',
                                  style: TextStyle(color: Colors.black),
                                ),
                                onPressed: () {
                                  tts.pause();
                                },
                              ),
                            ),
                          ),
                        if (supportResume)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.only(right: 10),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber),
                                child: const Text(
                                  'Resume',
                                  style: TextStyle(color: Colors.black),
                                ),
                                onPressed: () {
                                  tts.resume();
                                },
                              ),
                            ),
                          ),
                        Expanded(
                            child: Container(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber),
                            child: const Text(
                              'Speak',
                              style: TextStyle(color: Colors.black),
                            ),
                            onPressed: () {
                              speak();
                            },
                          ),
                        ))
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get supportPause => defaultTargetPlatform != TargetPlatform.android;

  bool get supportResume => defaultTargetPlatform != TargetPlatform.android;

  void speak() {
    tts.setVolume(volume);
    tts.setRate(rate);
    if (languageCode != null) {
      tts.setLanguage(languageCode!);
    }
    tts.setPitch(pitch);
    tts.speak(text);
  }
}
