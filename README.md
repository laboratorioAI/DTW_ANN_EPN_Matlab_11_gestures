# DTW_ANN_EPN_Matlab_11_gestures

MATLAB implementation of an EMG-based Hand Gesture Recognition Model using **Dynamic Time Warping (DTW)** and a **feed-forward Artificial Neural Network (ANN)**. 

> **Implementation note:** Although the repository is named `DTW_ANN_EPN_Matlab_11_gestures`, the current implementation defines **12 gesture classes**: one relaxation class (`relax`) and 11 active gestures.

---

## Overview

This project implements a complete EMG hand-gesture recognition pipeline comprising:

1. Dataset loading from JSON files.
2. EMG normalisation.
3. EMG rectification.
4. Low-pass filtering.
5. Automatic muscle-activity segmentation.
6. Extraction of representative time-series centres for each gesture class using DTW.
7. DTW-based feature extraction.
8. Feature-vector preprocessing.
9. Training of a feed-forward neural network with a softmax output layer.
10. Sliding-window classification of testing EMG signals.
11. Temporal post-processing and majority voting.
12. Generation of recognition results in JSON format.

The main execution script is:

```text
main.m
```

---

# 1. Project Structure

```text
DTW_ANN_EPN_Matlab_11_gestures/
│
├── DTW distance/
│   ├── compileDTWC.m
│   ├── dtw_c.c
│   ├── dtw_c.m
│   ├── dtw_c.mexmaci64
│   └── dtw_c.mexw64
│
├── Feature extraction/
│   └── featureExtraction.m
│
├── Preprocessing/
│   ├── majority_vote.m
│   ├── preProcessEMGSegment.m
│   └── rectifyEMG.m
│
├── ReadDataset/
│   ├── code2gesture.m
│   ├── codeSamples.m
│   └── gesture2code.m
│
├── Segmentation/
│   ├── code2gesture.m
│   └── detectMuscleActivity.m
│
├── TrainingModel/
│   ├── computeNumericalGradient.m
│   ├── elu.m
│   ├── fmincg.m
│   ├── forwardPropagation.m
│   └── softmaxNNCostFunction.m
│
├── filesReadme/
│   ├── CopyDataset.png
│   ├── Dataset.png
│   ├── Email.png
│   ├── I1.png
│   ├── I2.png
│   ├── ...
│   ├── Scores.png
│   ├── SystemEvaluation.png
│   └── Zenodo.png
│
├── testingJSON/
│   └── user_001/
│       ├── user_001.json
│       └── photo.png
│
├── trainingJSON/
│   └── user_001/
│       ├── user_001.json
│       └── photo.png
│
├── main.m
├── options.mat
├── recognitionModel.m
├── recognitionModel.asv
├── responses.json
├── LICENSE
└── README.md
```

The file `recognitionModel.asv` is an AutoSave/backup version of the MATLAB class and is not called by `main.m`.

---

# 2. Recognition Pipeline

The implemented processing chain is:

```text
JSON Dataset
     │
     ▼
Read EMG data
     │
     ▼
Normalisation
     │
     ▼
Rectification
     │
     ▼
Low-pass filtering
     │
     ▼
Muscle-activity segmentation
     │
     ▼
Representative DTW centres
     │
     ▼
DTW distance feature extraction
     │
     ▼
Feature-vector preprocessing
     │
     ▼
Feed-forward ANN
     │
     ▼
Sliding-window classification
     │
     ▼
Probability threshold
     │
     ▼
Majority voting
     │
     ▼
Temporal post-processing
     │
     ▼
Final gesture labels
     │
     ▼
responses.json
```

---

# 3. Gesture Classes

The implementation defines the following gesture-code mapping:

| Code | Gesture    |
| ---: | ---------- |
|    1 | `relax`    |
|    2 | `waveIn`   |
|    3 | `waveOut`  |
|    4 | `fist`     |
|    5 | `open`     |
|    6 | `pinch`    |
|    7 | `up`       |
|    8 | `down`     |
|    9 | `left`     |
|   10 | `right`    |
|   11 | `forward`  |
|   12 | `backward` |

The same mapping is implemented by `gesture2code.m` and `code2gesture.m`.

The dataset JSON also contains a `datasetGestureLabel` field with zero-based labels:

```text
relax    = 0
fist     = 1
waveIn   = 2
waveOut  = 3
open     = 4
pinch    = 5
up       = 6
down     = 7
left     = 8
right    = 9
forward  = 10
backward = 11
```

The recognition model internally uses the one-based class codes listed above.

---

# 4. Dataset Format

The example JSON files contain the following main sections:

```text
generalInfo
userInfo
synchronizationGesture
trainingSamples
testingSamples
```

The repository's example dataset uses a **Myo Armband** with:

* Sampling frequency: **200 Hz**
* Recording time: **5 seconds**
* 8 EMG channels

Each EMG sample contains:

```text
emg
├── ch1
├── ch2
├── ch3
├── ch4
├── ch5
├── ch6
├── ch7
└── ch8
```

The training samples additionally contain a `gestureName`, which allows the implementation to determine the ground-truth class.

Testing samples do not provide `gestureName` to the recognition algorithm. Their ordering is therefore used to reconstruct the class organisation.

The example user contains:

* **180 training samples**
* **180 testing samples**
* **12 gesture classes**
* **15 training repetitions per class**
* **15 testing repetitions per class**

The repository therefore provides an example dataset sufficient to execute the complete pipeline.

---

# 5. Dataset Directory Convention

`main.m` determines the dataset directory from:

```matlab
userFolder = 'testing';
folderData = [userFolder 'JSON'];
```

With the default configuration, the program therefore reads:

```text
testingJSON/
```

The expected structure for each user is:

```text
testingJSON/
└── user_001/
    └── user_001.json
```

The JSON filename must correspond to the user directory/name expected by the code.

The repository also contains:

```text
trainingJSON/
```

with the same general organisation.

---

# 6. Running the Model

## 6.1 Open MATLAB

Open the repository directory as the MATLAB working directory.

## 6.2 Verify the DTW MEX Function

The project contains precompiled DTW MEX binaries:

```text
DTW distance/dtw_c.mexmaci64
DTW distance/dtw_c.mexw64
```

The source implementation is:

```text
DTW distance/dtw_c.c
```

A compilation script is also provided:

```text
DTW distance/compileDTWC.m
```

Run the compilation script when a compatible MEX binary is not available for the current platform:

```matlab
cd('DTW distance')
compileDTWC
cd('..')
```

The compilation command used by the project is:

```matlab
mex dtw_c.c
```

---

## 6.3 Execute the Main Script

From the repository root:

```matlab
main
```

`main.m` automatically adds the following directories to the MATLAB path:

```matlab
ReadDataset
Preprocessing
Segmentation
DTW distance
TrainingModel
Feature extraction
```

---

# 7. Main Execution Process

`main.m` performs the following operations for every user found in the selected JSON directory.

### 7.1 Load configuration

```matlab
load options.mat
```

The random-number generator is then initialised using:

```matlab
rng('default');
```

This is intended to make the model initialisation reproducible.

### 7.2 Load the user JSON

The user's JSON file is read using:

```matlab
text = fileread(file);
user = jsondecode(text);
```

### 7.3 Create the recognition model

For training:

```matlab
currentUserTrain = recognitionModel( ...
    user, ...
    'training', ...
    gestures, ...
    options);
```

For testing:

```matlab
currentUserTest = recognitionModel( ...
    user, ...
    'testing', ...
    gestures, ...
    options);
```

---

# 8. Training Stage

For each user, the model is trained using that user's training samples.

The training sequence is:

```text
Training JSON
     │
     ▼
getTotalXnYByUser()
     │
     ▼
preProcessEMG()
     │
     ▼
makeSingleSet()
     │
     ▼
findCentersOfEachClass()
     │
     ▼
featureExtraction()
     │
     ▼
preProcessFeatureVectors()
     │
     ▼
trainSoftmaxNN()
```

## 8.1 Reading Training Samples

`getTotalXnYByUser()` reads the eight EMG channels and divides their values by 128:

```matlab
EMG(:,ch) = emgData.(channel) / 128;
```

The class is obtained from the sample's `gestureName`.

---

# 9. EMG Preprocessing

The preprocessing implementation is contained in:

```text
Preprocessing/preProcessEMGSegment.m
Preprocessing/rectifyEMG.m
```

The default configuration in `options.mat` is:

| Parameter                   |       Value |
| --------------------------- | ----------: |
| Rectification               |       `abs` |
| Sampling frequency          |      200 Hz |
| Segmentation                |     enabled |
| Segmentation rectification  |       `abs` |
| Minimum segmentation length | 100 samples |
| Spectral threshold          |          10 |

## 9.1 Normalisation

If the absolute maximum EMG value is greater than 1, the signal is divided by 128.

```matlab
EMGnormalized = EMGsegment_in/128;
```

Otherwise, the signal is retained.

## 9.2 Rectification

Three rectification modes are implemented:

```text
square
abs
none
```

The default configuration uses:

```text
abs
```

Therefore:

```matlab
rectifiedEMG = abs(rawEMG);
```

## 9.3 Filtering

The rectified signal is filtered using zero-phase filtering:

```matlab
filtfilt(Fb, Fa, EMGrectified);
```

The filter coefficients are stored in `options.mat`.

---

# 10. Automatic Muscle-Activity Segmentation

Segmentation is implemented in:

```text
Segmentation/detectMuscleActivity.m
```

The algorithm:

1. Sums the EMG envelopes across channels.
2. Computes a spectrogram.
3. Takes the magnitude of the spectrogram.
4. Sums the spectral magnitude across frequencies.
5. Applies a threshold.
6. Determines the beginning and end of the active region.
7. Adds 25 samples before and after the detected region.
8. Falls back to the complete signal if the resulting segment is shorter than the minimum allowed length.

The implementation uses:

```text
Spectrogram window length:       25 samples
Overlap:                         10 samples
Number of frequency points:      50
Minimum segmentation length:     100 samples
Additional samples at each end: 25
```

The sampling frequency is taken from:

```matlab
options.fs
```

and is set to:

```text
200 Hz
```

---

# 11. Representative Centre Selection Using DTW

After preprocessing, the training samples are grouped by class.

For each class, the implementation computes pairwise DTW distances between all samples belonging to that class.

The distance matrix is then summed for each sample. The sample with the smallest total distance to the other samples is selected as the class centre.

Conceptually:

```text
Class samples
     │
     ├── DTW(sample 1, sample 2)
     ├── DTW(sample 1, sample 3)
     ├── ...
     │
     ▼
Pairwise distance matrix
     │
     ▼
Distance sum for every sample
     │
     ▼
Sample with minimum total distance
     │
     ▼
Class centre
```

This produces one representative time series for each gesture class.

The resulting centres are stored in:

```matlab
nnModel.centers
```

---

# 12. Dynamic Time Warping

DTW is implemented through the C/MEX function:

```text
DTW distance/dtw_c.c
```

and exposed to MATLAB as:

```matlab
dtw_c(...)
```

The DTW window is configured through:

```matlab
options.dtwWindow
```

The supplied configuration uses:

```text
dtwWindow = 1000
```

The DTW implementation is used in two principal locations:

1. Selecting representative centres.
2. Converting EMG time series into ANN feature vectors.

---

# 13. DTW Feature Extraction

`Feature extraction/featureExtraction.m` computes one feature for every combination of:

```text
input time series × class centre
```

For a given signal, each feature is its DTW distance to one class centre.

Therefore, with 12 centres, each signal produces a 12-dimensional DTW feature vector.

Conceptually:

```text
EMG signal
   │
   ├── DTW → centre 1
   ├── DTW → centre 2
   ├── DTW → centre 3
   │      ...
   └── DTW → centre 12
             │
             ▼
       DTW feature vector
```

The resulting matrix has the form:

```text
[number of samples × number of centres]
```

---

# 14. Feature-Vector Preprocessing

The available preprocessing methods are:

```text
vector
feature
minmax
none
```

The supplied configuration uses:

```text
typePreprocessingFeatVector = 'vector'
```

For `vector`, each feature vector is standardised independently:

```matlab
(dataX_in - mean(dataX_in)) / std(dataX_in)
```

The other available modes are:

### `feature`

Each feature is standardised across the complete set of samples.

### `minmax`

The feature values are scaled according to the global minimum and maximum.

### `none`

No preprocessing is applied.

---

# 15. Artificial Neural Network

The neural network is implemented directly in MATLAB rather than relying on a high-level neural-network training framework.

The architecture is defined in the `recognitionModel` constructor:

```matlab
obj.numNeuronsLayers = ...
    [length(gesture) length(gesture) length(gesture)];
```

Since the implementation defines 12 gestures, this corresponds to:

```text
Input layer:   12 neurons
Hidden layer:  12 neurons
Output layer:  12 neurons
```

The configured transfer functions are:

```text
Input:  none
Hidden: tanh
Output: softmax
```

Thus the model is:

```text
12-dimensional DTW feature vector
             │
             ▼
       Hidden layer
       12 neurons
          tanh
             │
             ▼
       Output layer
       12 neurons
        softmax
             │
             ▼
       Class probabilities
```

---

# 16. Neural-Network Training

Training is implemented in:

```text
TrainingModel/softmaxNNCostFunction.m
TrainingModel/forwardPropagation.m
TrainingModel/fmincg.m
```

The network weights are randomly initialised using a range based on:

```matlab
sqrt(6) / sqrt(numNeuronsLayers(i) + ...
               numNeuronsLayers(i - 1) + 1)
```

The optimisation uses the supplied implementation of:

```text
fmincg
```

The configured number of iterations is:

```text
500
```

The regularisation parameter is:

```text
lambda = 0.01
```

The cost function combines:

1. Multiclass cross-entropy.
2. L2 weight regularisation.

The implementation performs back-propagation to calculate the gradient.

---

# 17. Supported Neural-Network Transfer Functions

`forwardPropagation.m` supports:

```text
logsig
relu
tanh
softplus
elu
softmax
```

The current recognition model uses:

```text
tanh
softmax
```

The `elu.m` function is included separately.

`computeNumericalGradient.m` is also included in the training-model directory.

---

# 18. Testing and Classification

Testing uses a sliding-window approach.

The default parameters are:

| Parameter     |       Value |
| ------------- | ----------: |
| Window length | 600 samples |
| Stride        |  30 samples |

For every testing signal:

```text
EMG signal
    │
    ▼
600-sample window
    │
    ▼
Advance 30 samples
    │
    ▼
Next window
    │
    ▼
...
```

The number of classifications is calculated as:

```matlab
floor((emgLength - windowLength) / strideLength) + 1
```

---

# 19. Handling Short Signals

If a signal is shorter than the configured 600-sample window, the implementation calculates the number of missing samples.

If the missing amount is less than or equal to the stride length, the final observation is repeated until the signal reaches the required window length.

If the signal is missing more than one stride, an error is raised.

This prevents substantially shorter signals from being silently processed as normal input.

---

# 20. Classification of Each Window

For each sliding window:

1. The window is optionally segmented.
2. The EMG is rectified and filtered.
3. DTW features are calculated against the class centres.
4. The feature vector is preprocessed.
5. The ANN calculates class probabilities.
6. The class with the highest probability is selected.
7. If the highest probability is at most `0.5`, the prediction is changed to `relax`.

The probability threshold is therefore:

```text
0.5
```

---

# 21. Temporal Majority Voting

The sequence of window-level predictions is passed through:

```text
Preprocessing/majority_vote.m
```

The current implementation uses:

```matlab
majority_vote(predLabelSeq, 6, 6)
```

Therefore, each prediction is evaluated using a temporal window extending:

```text
6 predictions before
6 predictions after
```

The class receiving the largest number of votes is selected.

If there is a tie, MATLAB's `max` behaviour results in the lower class code being selected.

---

# 22. Temporal Post-Processing

The model then applies an additional post-processing step through:

```matlab
posProcessLabels()
```

The first classification is explicitly forced to:

```text
relax
```

For subsequent predictions, the implementation compares each prediction with the immediately preceding prediction.

If the two predictions are equal, the current prediction is converted to:

```text
relax
```

If they differ, the current prediction is retained.

The final class for each sample is then obtained from the post-processed sequence.

---

# 23. Processing-Time Measurement

The system measures processing time for the different stages of classification, including:

* Window acquisition/extraction.
* Filtering.
* DTW feature extraction.
* ANN classification.
* Probability thresholding.
* Post-processing.

The time information is retained alongside the recognition results.

`computeTime()` combines classification and post-processing timing information.

---

# 24. Output

The final output is written to:

```text
responses.json
```

using:

```matlab
generateResultsJSON()
```

The JSON output contains a `testing` section and user-specific results.

The recognition result structure contains:

```text
class
vectorOfLabels
vectorOfProcessingTime
vectorOfTimePoints
```

For each sample, the output uses identifiers such as:

```text
idx_1
idx_2
idx_3
...
```

The final `class` field contains the final gesture classification.

`vectorOfLabels` contains the sequence of window-level predictions.

`vectorOfTimePoints` contains the temporal position associated with each classification.

`vectorOfProcessingTime` contains the processing-time measurements.

---

# 25. Example Output Structure

Conceptually, the generated JSON follows this organisation:

```json
{
    "testing": {
        "user_001": {
            "class": {
                "idx_1": "relax",
                "idx_2": "backward"
            },
            "vectorOfLabels": {
                "idx_1": [
                    "relax",
                    "relax",
                    "waveIn"
                ]
            },
            "vectorOfProcessingTime": {
                "idx_1": [
                    0.001
                ]
            },
            "vectorOfTimePoints": {
                "idx_1": [
                    310
                ]
            }
        }
    }
}
```

The numerical values above illustrate the structure only; the repository's actual `responses.json` contains the generated results.

---

# 26. Configuration

All principal model parameters are stored in:

```text
options.mat
```

The supplied configuration contains:

| Parameter                       |    Value |
| ------------------------------- | -------: |
| `rectFcn`                       |    `abs` |
| `Segmentation`                  |      `1` |
| `rectFcnSegmentation`           |    `abs` |
| `fs`                            |    `200` |
| `minWindowLengthOfSegmentation` |    `100` |
| `threshForSumAlongFreqInSpec`   |     `10` |
| `plotSignals`                   |      `0` |
| `dtwWindow`                     |   `1000` |
| `windowLength`                  |    `600` |
| `strideLength`                  |     `30` |
| `typePreprocessingFeatVector`   | `vector` |
| `lambda`                        |   `0.01` |
| `numIterations`                 |    `500` |

The filter coefficient vectors `Fa`, `Fb`, `FaSegmentation` and `FbSegmentation` are also stored in `options.mat`.

---

# 27. Visualisation

The segmentation code supports signal visualisation through:

```matlab
options.plotSignals
```

When enabled, the implementation produces figures showing:

* The spectrogram.
* The summed EMG envelopes.
* The detected activity region.
* Raw EMG signals.
* Filtered EMG signals.
* Channel-by-channel processing.

The default value in the supplied configuration is:

```text
plotSignals = 0
```

so visualisation is disabled during normal execution.

---

# 28. Important Implementation Details

### Training is performed per user

`main.m` constructs and trains a separate model for each user processed by the loop.

The model is not loaded from a pre-trained neural-network file.

Instead, the following are calculated for each user:

```text
DTW class centres
DTW feature vectors
feature preprocessing
ANN weights
```

### The model uses the user's training data

The training samples are read from:

```text
trainingSamples
```

inside the user's JSON object.

### Testing is performed on the user's testing samples

The testing samples are read from:

```text
testingSamples
```

and are processed without using their gesture name as an input to the classifier.

### Eight EMG channels are used

Only:

```text
ch1 ... ch8
```

are assembled into the EMG matrix used by the recognition model.

Although the JSON dataset also contains quaternion, gyroscope and accelerometer information, the recognition pipeline implemented here uses the EMG channels for classification.

---

# 29. MATLAB Functions by Module

## DTW distance

### `compileDTWC.m`

Compiles the C DTW implementation into a MATLAB MEX function.

### `dtw_c.c`

C implementation used by the MATLAB MEX interface.

### `dtw_c.m`

MATLAB documentation/demo file for the DTW MEX function.

---

## Feature extraction

### `featureExtraction.m`

Computes DTW distances between every input time series and every class centre.

---

## Preprocessing

### `preProcessEMGSegment.m`

Performs:

```text
normalisation
→ rectification
→ filtering
```

### `rectifyEMG.m`

Provides:

```text
square
abs
none
```

rectification modes.

### `majority_vote.m`

Performs temporal majority voting over the sequence of predicted classes.

---

## Dataset handling

### `gesture2code.m`

Converts gesture names into internal class codes.

### `code2gesture.m`

Converts internal class codes into gesture names.

### `codeSamples.m`

Obtains the class code associated with a training sample's `gestureName`.

---

## Segmentation

### `detectMuscleActivity.m`

Detects the region of an EMG signal associated with muscle activity using a spectrogram-based procedure.

### `code2gesture.m`

Provides the same gesture-code-to-name mapping within the segmentation module.

---

## Neural-network training

### `forwardPropagation.m`

Computes neural-network activations and intermediate values.

### `softmaxNNCostFunction.m`

Calculates:

* Network cost.
* Cross-entropy.
* L2 regularisation.
* Back-propagation gradients.

### `fmincg.m`

Provides the optimisation procedure used to train the network.

### `elu.m`

Implements the exponential linear unit activation.

### `computeNumericalGradient.m`

Provides numerical gradient calculation functionality.

---

## Recognition model

### `recognitionModel.m`

Contains the main recognition-model class and coordinates:

* Dataset reading.
* Preprocessing.
* Class-centre calculation.
* Feature extraction.
* Feature preprocessing.
* Neural-network training.
* Sliding-window classification.
* Temporal post-processing.
* Timing calculations.
* Result generation.

---

# 30. Complete Execution Flow in `main.m`

The principal execution sequence is:

```text
Initialise MATLAB
      │
      ▼
Add project directories to MATLAB path
      │
      ▼
Load options.mat
      │
      ▼
Set reproducible random seed
      │
      ▼
Select userFolder
      │
      ▼
Find user JSON files
      │
      ▼
For each user
      │
      ├── Read JSON
      │
      ├── Create training recognitionModel
      │
      ├── Read training EMG
      │
      ├── Preprocess EMG
      │
      ├── Build single training set
      │
      ├── Find DTW centre for each class
      │
      ├── Extract DTW features
      │
      ├── Preprocess features
      │
      ├── Train softmax ANN
      │
      ├── Create testing recognitionModel
      │
      ├── Read testing EMG
      │
      ├── Sliding-window classification
      │
      ├── Majority voting
      │
      ├── Temporal post-processing
      │
      ├── Calculate processing times
      │
      └── Store recognition results
      │
      ▼
Generate responses.json
```

---

# 31. Reproducibility

The project explicitly initialises MATLAB's random-number generator with:

```matlab
rng('default');
```

The neural-network weights are nevertheless generated during each training operation.

The DTW centres are determined directly from the training data rather than randomly generated.

For reproducible experiments, the following should therefore be kept unchanged unless an experimental modification is intended:

```text
options.mat
dataset
gesture ordering
main.m
recognitionModel.m
DTW implementation
random-number initialisation
```

---

# 32. Current Repository Limitations and Observations

The following points are directly observable from the supplied repository.

### 32.1 Platform-specific MEX binaries

The repository contains:

```text
dtw_c.mexmaci64
dtw_c.mexw64
```

for macOS and Windows MATLAB environments respectively.

No Linux MEX binary is included. The C source and compilation script are provided to build the MEX function.

### 32.2 Dataset availability

The repository contains example JSON files under:

```text
trainingJSON/
testingJSON/
```

The full external dataset is detailed in the associated Data Descriptor Paper.
---

# 33. Licence

The repository includes the:

**GNU General Public License, Version 3, 29 June 2007 (GPLv3).**

The complete licence text is provided in:

```text
LICENSE
```

Any redistribution, modification or combination of this software should therefore be carried out in accordance with the licence included in the repository.

---

# 34. Summary

This repository implements a complete per-user EMG hand-gesture recognition pipeline based on:

```text
EMG
 ↓
Preprocessing
 ↓
Muscle-activity segmentation
 ↓
DTW-based representative centres
 ↓
DTW feature extraction
 ↓
Feature normalisation
 ↓
12-class feed-forward ANN
 ↓
Sliding-window recognition
 ↓
Majority voting
 ↓
Temporal post-processing
 ↓
JSON results
```

The current configuration uses **eight EMG channels**, a **200 Hz sampling frequency**, **600-sample classification windows**, a **30-sample stride**, a **DTW window of 1000**, and a **12-class ANN with 12 neurons in the input, hidden and output layers**.

The principal entry point is:

```matlab
main
```

and the principal model implementation is:

```text
recognitionModel.m
```
