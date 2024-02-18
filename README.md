# 🎾 Tennis Serve Analysis 

The Tennis Serve Analysis App is a mobile application designed to revolutionize the way tennis players analyze and improve their serves. Leveraging machine learning algorithms and computer vision techniques, the app provides users with personalized feedback, instant comparisons with professional players, and valuable insights into their serve mechanics.

Please star⭐ the repo if you like what you see😊.

## 💻 Installation links

[<img alt='Get it on Google Play' src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png" width="250">](https://play.google.com/store/apps/details?id=com.adeeteya.tennis_serve_analysis)

(or)

[![Download apk](https://img.shields.io/badge/Download-apk-green)](https://github.com/adeeteya/Tennis-Serve-Analysis/releases/download/1.0.0/Tennis-Serve-Analysis-android-1.0.0.apk)

## 📖 Usage

1. Launch the app on your mobile device.

2. Input your height and playing hand (left handed or right handed).

3. Upload a side serve video that you want to analyze.

4. View the analysis, including maximum,minimum and average joint angles and ball speed comparisons with a professional player (for now the players included are Roger Federer, Rafael Nadal and Fabio Fognini).

## ✨ Features

- 🦵 Pose Estimation: Utilizes MoveNet, a machine learning model, to estimate key points in the user's serve, including joints such as elbows, shoulders, and knees.

- 🧔 Professional Player Comparison: Allows users to compare their serve with a professional player of equivalent height, providing visual overlays and angle comparisons.

- 🥎 Ball Tracking: Employs AutoML Vision for ball detection and tracking, calculating the speed of the ball after impact.

- 👥 User Feedback: Provides real-time feedback on joint angles, enabling users to understand their technique and receive suggestions for improvement.

- 📊 Data-Driven Progress Tracking: Enables users to track their progress over time, helping them monitor improvements and refine their training strategies.

## 📸 Screen Recording

![Screen Recording](screen-recording/output-recording.gif)

## 🔌 Plugins

| Name                                                                        | Usage                                                        |
|-----------------------------------------------------------------------------|--------------------------------------------------------------|
| [**image_picker**](https://pub.dev/packages/image_picker)                   | For helpful image functions                                  |
| [**video_player**](https://pub.dev/packages/video_player)                   | To play,pause, slow down the selected analysis video         |
| [**ffmpeg_kit_flutter**](https://pub.dev/packages/ffmpeg_kit_flutter)       | To convert the video into individual frames for analysis     |
| [**path_provider**](https://pub.dev/packages/path_provider)                 | To access the temporary storage for the extracted images     |
| [**image**](https://pub.dev/packages/image)                                 | To process the extracted images from selected analysis video |
| [**tflite_flutter**](https://pub.dev/packages/tflite_flutter)               | To run tensorflow lite models                                |
| [**tflite_flutter_helper**](https://pub.dev/packages/tflite_flutter_helper) | Helper Functions for Machine Learning                        |
| [**lottie**](https://pub.dev/packages/lottie)                               | To display animations                                        |
| [**flutter_svg**](https://pub.dev/packages/flutter_svg)                     | To display svg images                                        |
| [**flutter_riverpod**](https://pub.dev/packages/flutter_riverpod)           | Used for State Management                                    |
| [**collection**](https://pub.dev/packages/collection)                       | Useful helper functions for List Data Type                   |
| [**flutter_lints**](https://pub.dev/packages/flutter_lints)                 | For linting                                                  |

## 🤓 Author

**[Aditya R](https://github.com/adeeteya)**

## 🔖 LICENCE
Copyright (c) 2024 Aditya R
[GNU GPLv3 LICENCE](https://github.com/adeeteya/Tennis-Serve-Analysis/blob/master/LICENSE)

## 🙏 Attributions
<a href="https://www.flaticon.com/free-icons/tennis" title="tennis icons">Tennis icons created by kerismaker - Flaticon</a>

Special thanks to the developers of MoveNet and AutoML Vision for their contributions to pose estimation and ball tracking in this app.