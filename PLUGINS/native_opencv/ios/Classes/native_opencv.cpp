#include <chrono>
// #include <string>
// #include <cstring>

#ifdef __ANDROID__
#include <android/log.h>
#endif
#include <opencv2/opencv.hpp>
#include <opencv2/imgproc.hpp>
#include <vector>

#include <istream>
#include <string>
#include <stdint.h>
#include <stdio.h>

#include "NeuronPrototype.cpp"

using namespace cv;
using namespace std;
#if defined(__GNUC__)
    // Attributes to prevent 'unused' function from being removed and to make it visible
    #define FUNCTION_ATTRIBUTE __attribute__((visibility("default"))) __attribute__((used))
#elif defined(_MSC_VER)
    // Marking a function for export
    #define FUNCTION_ATTRIBUTE __declspec(dllexport)
#endif

#ifdef __cplusplus
#define EXTERNC extern "C"
#else
#define EXTERNC
#endif

long long int get_now() {
    return chrono::duration_cast<std::chrono::milliseconds>(
            chrono::system_clock::now().time_since_epoch()
    ).count();
}
#ifdef IS_WIN32
#include <windows.h>
#endif



EXTERNC void platform_log_cv(const char *fmt, ...) {
    va_list args;
    va_start(args, fmt);
#ifdef __ANDROID__
    __android_log_vprint(ANDROID_LOG_VERBOSE, "ndk", fmt, args);
#elif defined(IS_WIN32)
    char *buf = new char[4096];
    std::fill_n(buf, 4096, '\0');
    _vsprintf_p(buf, 4096, fmt, args);
    OutputDebugStringA(buf);
    delete[] buf;
#else
    vprintf(fmt, args);
#endif
    va_end(args);
}


class cca_opencv_wrapper{

    private:

        Mat inp;
        Mat labels;
        Mat stats;
        Mat centroids;

    public:
        int max_idx = -1;
        int numObjects = 0;

        void clearAll()
        {
            inp.release();
            labels.release();
            stats.release();
            centroids.release();
        }

        cca_opencv_wrapper( Mat input )
        {
            inp = input.clone();
            labels = Mat(input.size(), CV_16U);
            // labels = Mat(input.size(), CV_32S);

            if(inp.channels() == 3)
                cvtColor(inp, inp, cv::COLOR_BGR2GRAY);
            connectedComponentsWithStats(inp, labels, stats, centroids, 8, CV_16U);
            // connectedComponentsWithStats(inp, labels, stats, centroids, 8, CV_32S);

        }


        Mat getCentroids(){
            return centroids;
        }

        Mat getLabels(){
            return labels;
        }

        uint32_t get_most_left_of_centroid(int centroid_index)
        {
            return stats.at<int>(centroid_index, CC_STAT_LEFT);
        }
        
        uint32_t get_most_top_of_centroid(int centroid_index)
        {
            return stats.at<int>(centroid_index, CC_STAT_TOP);
        }
        
        uint32_t get_width_of_centroid(int centroid_index)
        {
            return stats.at<int>(centroid_index, CC_STAT_WIDTH);
        }
        
        uint32_t get_heigth_of_centroid(int centroid_index)
        {
            return stats.at<int>(centroid_index, CC_STAT_HEIGHT);
        }
        
        uint32_t get_area_of_component(int centroid_index)
        {
            // return 0;
            return stats.at<int>(centroid_index, CC_STAT_AREA);
        }
        
        uint16_t get_label_of_pixel(int x_pos, int y_pos)
        {
            return labels.at<uint16_t>(x_pos, y_pos);
        }

        double get_centroid_x(int index)
        {
            // Centroids are strictly CV_64F (double)
            return centroids.at<double>(index, 0);
        }

        double get_centroid_y(int index)
        {
             return centroids.at<double>(index, 1);
        }

        size_t get_connected_component_count()
        {
            return centroids.rows;
        }

        uint32_t get_max_component_area()
        {
            uint32_t max_ = 0;
            for(auto iStep = 0; iStep < get_connected_component_count(); iStep++)
            {
                if(get_area_of_component(iStep) > max_ && iStep > 0){
                    max_ = get_area_of_component(iStep);
                    max_idx = iStep;
                }
            }
            return max_;
        }

        uint32_t get_min_component_area()
        {
            uint32_t min_ = inp.rows * inp.cols;
            for(auto iStep = 0; iStep < get_connected_component_count(); iStep++)
            {
                if(get_area_of_component(iStep) < min_)
                    min_ = get_area_of_component(iStep);
            }
            return min_;
        }

        float get_average_component_area()
        {
            uint32_t sum = 0;
            for(auto iStep = 0; iStep < get_connected_component_count(); iStep++)
            {
                sum = sum + get_area_of_component(iStep);
            }
            return ((float) sum) / (float) get_connected_component_count();
        }

        float get_standard_deviation_of_connected_compenent_areas()
        {
            float sum = 0;
            for(auto iStep = 0; iStep < get_connected_component_count(); iStep++)
            {
                sum = sum + ( abs( get_area_of_component(iStep) - get_average_component_area() ) );
            }
            return ((float) sum) / (float) get_connected_component_count();
        }

};



double sigmoid(double xx, double cc, double aa) {
    return 1.0 / (1.0 + exp(-aa * (xx - cc)));
}
// GLOBAL Variable
EXTERNC bool isPrevEyesSaved = false;
Mat prev_left_eye_frame, prev_right_eye_frame;
// Size net_input_size = Size(224,224);
Size net_input_size = Size(320,240);

bool isInitialized = false;
short resetCounter = 0;

void initializeCameraConstant(){
    platform_log("initializeCameraConstant called. Waiting for passPreprocessPointers from Dart.\n");
}

void setPreprocessMatrixValue(double *arr, short pi, short pj, short per_row, double value){
// vis_pref_vals, ncol * 2, icam, per_row, temp);
    if (arr == nullptr) return;
    int index = pj * per_row + pi;
    // Assuming max limit based on typical usage logic (22 * 2 = 44)
    if (index >= 0 && index < 44) {
        arr[index] =  value;
    } else {
        // platform_log("Error: setPreprocessMatrixValue out of bounds. Index: %d, Max: 44\n", index);
    }
}


// Avoiding name mangling
// extern "C" {
    // Attributes to prevent 'unused' function from being removed and to make it visible
    // __attribute__((visibility("default"))) __attribute__((used))
    EXTERNC FUNCTION_ATTRIBUTE
    const char* version() {
        return CV_VERSION;
    }

    EXTERNC FUNCTION_ATTRIBUTE
    int initializeOpenCV(){
        initializeCameraConstant();
        isPrevEyesSaved = false;
        return 1;
    }

    EXTERNC FUNCTION_ATTRIBUTE
    EXTERNC FUNCTION_ATTRIBUTE
    int passPreprocessPointers(int *p_state_buf, double *p_vis_pref_vals, short *p_vis_prefs, double *p_neuron_contacts){
        vis_pref_vals = p_vis_pref_vals;
        visPrefs = p_vis_prefs;
        neuron_contacts = p_neuron_contacts;
        fprintf(stderr, "passPreprocessPointers_opencv: Pointers assigned. vis_pref_vals=%p\n", vis_pref_vals);
        return 1;
    }


    // __attribute__((visibility("default"))) __attribute__((used))
    // void process_image(char* inputImagePath, char* outputImagePath) {
    EXTERNC FUNCTION_ATTRIBUTE
    // int findColorInImage(uint8_t* img, uint32_t imgLength, uint8_t* lowerB, uint8_t* upperB, uint8_t colorSpace, uint8_t* imgMask) {
    // int findColorInImage(uint8_t *img, uint32_t imgLength, uint8_t* imgMask) {
    int findColorInImage_opencv(uint8_t *img, uint32_t imgLength, uint16_t *centroid, uint8_t *debugImageBuffer, float *boundingBoxes, int boundingBoxesCount, int activeColors) {
        // Explicitly zero out centroid buffer to prevent any garbage values
        if (centroid != nullptr) {
            memset(centroid, 0, 100 * sizeof(uint16_t));
        }
        fprintf(stderr, "findColorInImage_opencv: START. img=%p, len=%d, activeColors=%d\n", img, imgLength, activeColors);

        // Mat rawImageRgb = Mat(240 * 320 * 4, 1, CV_8UC4, img);
        // Mat matImageRgb = rawImageRgb.reshape(4, 240);
        // // Mat matImageRgb = Mat(240, 320, CV_8UC4, img);
        // Mat imageRgb;
        // cvtColor(matImageRgb, imageRgb, COLOR_RGBA2BGR);

        // Mat imageRgb = Mat(240, 320, CV_8UC3, cv::Scalar(0,0,255));
        // cvtColor(src, imageRgb, COLOR_BGRA2BGR);

        // EM_ASM({
        //     console.log("pixVal[0] : ", $0,$1,$2,$3);
        // },pixVal[0],pixVal[1],pixVal[2],pixVal[3]);
        // EM_ASM({
        //     console.log("pixVal[0] : ", $0,$1,$2,$3);
        // },img[0],img[1],img[2],img[3]);
        
        // set pixels one by one
        // int imgCounter = 0;
        Mat srcImageRgb;
        Mat imageRgb;
 
        #ifdef __EMSCRIPTEN__
            srcImageRgb = Mat(240, 320, CV_8UC4, Scalar(0,0,0,255));
            for (int i=0; i<240;i++){
                for (int j=0; j<320; j++){
                    Vec4b pixVal = srcImageRgb.at<Vec4b>(i, j);
                    pixVal[2] = img[imgCounter++];
                    pixVal[1] = img[imgCounter++];
                    pixVal[0] = img[imgCounter++];
                    // pixVal[0] = img[imgCounter];
                    pixVal[3] = img[imgCounter++];
                    srcImageRgb.at<Vec4b>(i, j)=pixVal;

                }
            }
            cvtColor(srcImageRgb, imageRgb, COLOR_BGRA2BGR);            
        #else
            // platform_log("Start decode buffer");
            vector<uint8_t> buffer(img, img + imgLength);
            try {
                fprintf(stderr, "findColorInImage_opencv: About to imdecode. Buffer size: %lu\n", buffer.size());
                imageRgb = imdecode(buffer, IMREAD_COLOR);
                fprintf(stderr, "findColorInImage_opencv: imdecode success. Empty? %d\n", imageRgb.empty());
            } catch (cv::Exception& e) {
                platform_log("OpenCV Exception during imdecode: %s\n", e.what());
                return 0;
            } catch (...) {
                platform_log("Unknown Exception during imdecode\n");
                return 0;
            }
            if (imageRgb.empty()) return 0;
            
            // CRITICAL SAFETY CHECK: Ensure shared memory pointers are initialized
            if (vis_pref_vals == nullptr || visPrefs == nullptr) {
                // platform_log("Warning: Shared memory pointers not yet initialized. Skipping frame.\n");
                return 0;
            }
            buffer.clear();
            vector<uint8_t>().swap(buffer);            
            // platform_log("END decode buffer");

            if (imageRgb.empty()) {
                platform_log("Failed to decode image: imageRgb is empty\n");
                return 0;
            }
            // platform_log("Image decoded successfully\n");


        #endif
        
        // cvtColor(imageRgb, imageRgb, COLOR_RGBA2BGR);
        
        // Mat imageRgb = Mat(320, 240, CV_8UC4, img);

        Mat uframe, frame, grayFrame, xframe, leftFrame, rightFrame, bwframe;
        Mat leftGrayFrame, rightGrayFrame;
        // leftFrame = imageRgb(Rect(0, 0, frameSize, frameSize));
        // rightFrame = imageRgb(Rect(70, 0, frameSize, frameSize));
        // leftFrame = imageRgb(Rect(0, 0, frameSizeWidth, frameSizeHeight));
        leftFrame = imageRgb;

        // rightFrame = imageRgb(Rect(109, 15, frameSizeWidth, frameSizeHeight));
//         leftFrame = imageRgb(Rect(0, 0, 240, 240));
//         rightFrame = imageRgb(Rect(70, 0, 240, 240));

        if (!isPrevEyesSaved){
            // resize(leftFrame, prev_left_eye_frame, net_input_size);            
            // resize(rightFrame, prev_right_eye_frame, net_input_size);            
            isPrevEyesSaved = true;
        }


        // rightFrame = imageRgb(Range(80,1), Range(120-1,140-1));
        //cv::resize (InputArray src, OutputArray dst, Size dsize, double fx=0, double fy=0, int interpolation=INTER_LINEAR)
        std::string leftFrameResult = "000";
        std::string rightFrameResult = "000";
        

        for (short icam = 0; icam < 1; icam++){
            if (icam == 0){
                // Fix: Initialize uframe with leftFrame for processing
                uframe = leftFrame; 
                // Fix: grayFrame and leftGrayFrame are uninitialized, causing crash in subtract. 
                // Disabling background subtraction for now as it seems vestigial for color detection.
                // subtract(grayFrame, leftGrayFrame, xframe);
            }else{
                // resize(rightFrame, uframe, net_input_size);
                // cvtColor(uframe, grayFrame, COLOR_BGR2GRAY);
                // cvtColor(prev_right_eye_frame, rightGrayFrame, COLOR_BGR2GRAY);
                // subtract(grayFrame, rightGrayFrame, xframe);
            }

            // *** CV PIPELINE START ***
            if (icam == 0 && debugImageBuffer != nullptr) {
                Mat grayFrame, gray32, blurLight, blurHeavy, diff, xdog, thickEdges;
                
                // 1. Grayscale conversion
                cvtColor(uframe, grayFrame, COLOR_BGR2GRAY);
                
                // 2. Convert to float 0.0 - 1.0 for XDoG math
                grayFrame.convertTo(gray32, CV_32FC1, 1.0 / 255.0);
                
                // 2.5 Pre-Blur to eliminate JPEG compression macro-blocks (squares) native to ESP32 stream
                GaussianBlur(gray32, gray32, Size(3, 3), 0.5);
                
                // 3. XDoG Blurs
                GaussianBlur(gray32, blurLight, Size(0, 0), 1.0);
                GaussianBlur(gray32, blurHeavy, Size(0, 0), 2.5);
                
                // 4. XDoG Equation: S = g1 + p * (g1 - g2)
                float p = 15.0f; // Sharpness / edge amplification multiplier
                subtract(blurLight, blurHeavy, diff);
                xdog = blurLight + p * diff;
                
                // 5. Adaptive Epsilon (Threshold)
                // We detect room lighting to prevent the screen from going completely black 
                // in the dark, preserving detail in low-light environments.
                Scalar meanVal = mean(gray32);
                float meanBrightness = (float)meanVal[0];
                // Scale threshold dynamically, but enforce a hard minimum floor (0.18) 
                // to prevent raw camera sensor noise (pixelation blockiness) from being 
                // amplified as XDoG geometry when the room is nearly pitch black.
                float epsilon = std::max(0.18f, meanBrightness * 0.85f);
                
                // 6. Dollar-Bill Engraving Shading (Halftoning)
                // Instead of a flat binary threshold which groups camera noise into giant pixel squares,
                // we iterate spatially and draw ink strokes based strictly on illumination depth,
                // translating sensor noise naturally into printed shading gradients.
                thickEdges = Mat(xdog.size(), CV_8UC1, Scalar(255));
                for (int y = 0; y < xdog.rows; y++) {
                    float* dog_ptr = xdog.ptr<float>(y);
                    uint8_t* out_ptr = thickEdges.ptr<uint8_t>(y);
                    for (int x = 0; x < xdog.cols; x++) {
                        float val = dog_ptr[x];
                        
                        // Enforce a strong pure-black threshold for robust outlines and artifact-free deep shadows
                        if (val < epsilon * 0.80f) {
                            out_ptr[x] = 0;
                        } 
                        // Compress the shading tier mathematically so it strictly acts as a fast transitional gradient
                        // Favor pure white more by reducing the gradient width down to 0.18f
                        else if (val < epsilon + 0.18f) {
                            float shadowDepth = (val - (epsilon * 0.80f)) / (epsilon + 0.18f - epsilon * 0.80f); 
                            
                            // Taper lines naturally. strokeWidth drops from 2 down to 0 locally. 
                            int strokeWidth = 2 - (int)(shadowDepth * 3.0f); 
                            if (strokeWidth < 0) strokeWidth = 0;
                            
                            // Giant stretching sweeping organic sinusoid
                            float phaseX = 34.0f * std::sin(y * 0.017f);
                            float phaseY = 34.0f * std::sin(x * 0.017f);
                            
                            // Apply the sinusoid perpendicular to the gradient slope to create curving contours 
                            int field_val = (int)( (x + y)*1.0f + phaseX + phaseY + 10000.0f );
                            if (field_val % 8 <= strokeWidth) out_ptr[x] = 0;
                        }
                    }
                }
                
                // 8. Convert to BGRA for Dart GUI (BMP format compatibility)
                Mat displayFrame;
                cvtColor(thickEdges, displayFrame, COLOR_GRAY2BGRA);
                
                // Copy to shared memory buffer
                if (displayFrame.isContinuous()) {
                    memcpy(debugImageBuffer, displayFrame.data, 320 * 240 * 4);
                }
            }
            // *** CV PIPELINE END ***

            // platform_log("Converting to CV_32FC3...\n");
            // uframe.convertTo(frame, CV_32FC3); // Not used currently
            
                // Convert to HSV for robust color detection
                Mat hsvFrame;
                fprintf(stderr, "findColorInImage_opencv: About to cvtColor (BGR2HSV)\n");
                cvtColor(uframe, hsvFrame, COLOR_BGR2HSV);
                fprintf(stderr, "findColorInImage_opencv: cvtColor success\n");
                
                for (int ncol = 0; ncol < 3; ncol++) {
            // Check if this color is active in the bitmask
            // 1 (2^0) = Blue (ncol 0)
            // 2 (2^1) = Green (ncol 1)
            // 4 (2^2) = Red (ncol 2)
            if (!((activeColors >> ncol) & 1)) {
                // Skip this color if bit is 0
                 short tempCol = static_cast<short>(ncol * 2);
                 if (vis_pref_vals != nullptr) {
                    setPreprocessMatrixValue(vis_pref_vals, tempCol, 0, vis_prefs_count, 0);
                    setPreprocessMatrixValue(vis_pref_vals, tempCol + 1, 0, vis_prefs_count, 0);
                }
                continue; 
            }

            double this_score = 0;
            double curMaxScore = 0;
            double this_left_score = 0;
            double this_right_score = 0;
            double meanx = 0;

            fprintf(stderr, "findColorInImage_opencv: Loop start ncol=%d\n", ncol);
        
            Mat mask, mask1, mask2;

            if (ncol == 2) { // Red (Hue 0-6 and 165-180) - Tightened hue and bumped saturation to reject human skin tones (orange/pink bleed)
                inRange(hsvFrame, Scalar(0, 75, 40), Scalar(6, 255, 255), mask1);
                inRange(hsvFrame, Scalar(165, 75, 40), Scalar(180, 255, 255), mask2);
                bitwise_or(mask1, mask2, mask);
            } else if (ncol == 1) { // Green (Hue 34-77) - Gently lowered saturation floor to make it easier to see in medium light
                inRange(hsvFrame, Scalar(34, 85, 45), Scalar(77, 255, 255), mask);
            } else { // Blue (Hue 90-130) - Kept perfect
                inRange(hsvFrame, Scalar(90, 70, 35), Scalar(130, 255, 255), mask);
            }

            // Spatial Hysteresis (Morphological Operations) to reduce flickering and stabilize silhouettes
            Mat kernel = getStructuringElement(MORPH_RECT, Size(5,5));
            morphologyEx(mask, mask, MORPH_OPEN, kernel);  // Removes tiny noisy flicker pixels
            morphologyEx(mask, mask, MORPH_CLOSE, kernel); // Fills in gaps and solidifies the blob tracking
                fprintf(stderr, "findColorInImage_opencv: inRange done. cca starting...\n");
                cca_opencv_wrapper cca_wrapper = cca_opencv_wrapper(mask);
                fprintf(stderr, "findColorInImage_opencv: cca done. count=%lu\n", cca_wrapper.get_connected_component_count());
                if (cca_wrapper.get_connected_component_count() > 1) {
                    // Multi-Blob Support (Top 5) by sorting areas
                    std::vector<int> blobIndices;
                    for(auto iStep = 1; iStep < cca_wrapper.get_connected_component_count(); iStep++) {
                        blobIndices.push_back(iStep);
                    }
                    // Sort descending by area
                    std::sort(blobIndices.begin(), blobIndices.end(), [&](int a, int b) {
                        return cca_wrapper.get_area_of_component(a) > cca_wrapper.get_area_of_component(b);
                    });

                    // We will process up to 5 blobs
                    // Accumulate scores for Simulation
                    double total_this_score = 0;
                    double total_left_score = 0;
                    double total_right_score = 0;
                    
                    int blobsFound = 0;
                    
                    for (int k = 0; k < 5; k++) {
                        // Index in global buffer: (ncol * 5 + k) * 5
                        // Format: [x, y, score, w, h]
                        int baseBufIdx = (ncol * 5 + k) * 5;
                        
                        if (k < blobIndices.size()) {
                            int idx = blobIndices[k];
                            // Valid blob
                            double cx = cca_wrapper.get_centroid_x(idx);
                            double cy = cca_wrapper.get_centroid_y(idx);
                            int w_blob = cca_wrapper.get_width_of_centroid(idx);
                            int h_blob = cca_wrapper.get_heigth_of_centroid(idx);
                            
                            // Write to Centroid Buffer for UI
                            centroid[baseBufIdx + 0] = (short)cx;
                            centroid[baseBufIdx + 1] = (short)cy;
                            
                            // Calculate Score for this blob (using existing logic)
                            double max_size = (double)cca_wrapper.get_area_of_component(idx);
                            double b_score = sigmoid((double)max_size, 1000.0, 0.0075) * 70.0;
                            centroid[baseBufIdx + 2] = (short)b_score;
                            
                            // Width and Height
                            centroid[baseBufIdx + 3] = (short)w_blob;
                            centroid[baseBufIdx + 4] = (short)h_blob;
                            
                            // Accumulate for Simulation
                            double left_weight = sigmoid(((228.0 - cx) / 227.0), 0.85, 10.0);
                            double right_weight = sigmoid(((cx) / 227.0), 0.85, 10.0);
                            
                            total_this_score += b_score;
                            total_left_score += (left_weight * b_score);
                            total_right_score += (right_weight * b_score);

                            blobsFound++;

                            // Debug Overlay Drawing (Draw exact silhouette masks)
                            if (debugImageBuffer != nullptr) {
                                Mat debugMat(240, 320, CV_8UC4, debugImageBuffer);
                                int x = cca_wrapper.get_most_left_of_centroid(idx);
                                int y = cca_wrapper.get_most_top_of_centroid(idx);
                                int w = w_blob;
                                int h = h_blob;
                                int right = x + w;
                                int bottom = y + h;
                                Vec3b overlayColor(252, 150, 25);
                                if (ncol == 1) overlayColor = Vec3b(85, 238, 85);
                                else if (ncol == 2) overlayColor = Vec3b(68, 68, 255);

                                for (int i = y; i < bottom; i++) {
                                    for (int j = x; j < right; j++) {
                                        if (i < 0 || i >= 240 || j < 0 || j >= 320) continue;
                                        
                                        // DRAW RAW EXACT SILHOUETTE PIXELS INSTEAD OF BOXES
                                        if (cca_wrapper.getLabels().at<uint16_t>(i, j) == idx) {
                                            Vec4b &pixel = debugMat.at<Vec4b>(i, j);
                                            pixel[0] = (pixel[0] * overlayColor[0]) / 255;
                                            pixel[1] = (pixel[1] * overlayColor[1]) / 255;
                                            pixel[2] = (pixel[2] * overlayColor[2]) / 255;
                                        }
                                    }
                                }
                            }
                        } else {
                            // Clear unused slots
                            centroid[baseBufIdx + 0] = 0;
                            centroid[baseBufIdx + 1] = 0;
                            centroid[baseBufIdx + 2] = 0;
                            centroid[baseBufIdx + 3] = 0;
                            centroid[baseBufIdx + 4] = 0;
                        }
                    }

                    // Write accumulated scores for Simulation
                    meanx = 0; 
                    this_score = total_this_score;
                    this_left_score = total_left_score;
                    this_right_score = total_right_score;
                    
                    short tempCol = static_cast<short>(ncol * 2);

                    if (vis_pref_vals != nullptr) {
                        setPreprocessMatrixValue(vis_pref_vals, tempCol, icam, vis_prefs_count, this_score);
                         if (icam == 0) {
                            setPreprocessMatrixValue(vis_pref_vals, tempCol + 1, icam, vis_prefs_count, this_left_score);
                        } else {
                            setPreprocessMatrixValue(vis_pref_vals, tempCol + 1, icam, vis_prefs_count, this_right_score);
                        }
                    }


                } else {
                    meanx = 0;
                    this_score = 0;
                    this_left_score = 0;
                    this_right_score = 0;
                    short tempCol = static_cast<short>(ncol * 2);
                    if (vis_pref_vals != nullptr) {
                        setPreprocessMatrixValue(vis_pref_vals, tempCol, icam, vis_prefs_count, 0);
                        setPreprocessMatrixValue(vis_pref_vals, tempCol + 1, icam, vis_prefs_count, 0);
                    }
                    // Explicitly zero out centroid to prevent stale data
                    // FIX: Must use correct stride (5 blobs * 5 values = 25 per color)
                    for (int k = 0; k < 5; k++) {
                        int baseBufIdx = (ncol * 5 + k) * 5;
                        centroid[baseBufIdx + 0] = 0;
                        centroid[baseBufIdx + 1] = 0;
                        centroid[baseBufIdx + 2] = 0;
                        centroid[baseBufIdx + 3] = 0;
                        centroid[baseBufIdx + 4] = 0;
                    }
                }
                cca_wrapper.clearAll();
            }
            

            /*
            Mat channels[3];
            split(uframe, channels);
            // compare(xframe, 20, xframe, CMP_GT);
            threshold(xframe, bwframe, 20, 255, THRESH_BINARY);            

            cca_opencv_wrapper cca_wrapper_bw = cca_opencv_wrapper(bwframe);
            // break;
            if (cca_wrapper_bw.get_connected_component_count() > 0) {
                uint32_t max_size = 0;
                // int max_idx = 0;
                max_size = cca_wrapper_bw.get_max_component_area();
                // double meanx = cca_wrapper_bw.get_centroid_x(cca_wrapper_bw.max_idx);
                this_score = sigmoid(max_size, 1000, 0.0075) * 50;
            }else{
                this_score = 0;
            }


            // vis_pref_vals[6][ncam] = this_score;
            if (vis_pref_vals != nullptr) {
                // setPreprocessMatrixValue(vis_pref_vals, 6, icam, vis_prefs_count, this_score);
            }


            if (icam == 0){
                // prev_left_eye_frame = uframe;
            }else{
                // prev_right_eye_frame = uframe;
            }
            channels[0].release();
            channels[1].release();
            channels[2].release();

            cca_wrapper_bw.clearAll();
            */
        }
        
        // Draw Object Detection Bounding Boxes (People)
        if (debugImageBuffer != nullptr && boundingBoxes != nullptr && boundingBoxesCount > 0) {
            Mat debugMat(240, 320, CV_8UC4, debugImageBuffer);
            // BackyardBrains Orange: BGR(100, 129, 253) -> BGRA(100, 129, 253, 255)
            Vec4b overlayColor(100, 129, 253, 255);
            
            for (int k = 0; k < boundingBoxesCount; k++) {
                // Bounds
                float x = boundingBoxes[k*4 + 0];
                float y = boundingBoxes[k*4 + 1];
                float w = boundingBoxes[k*4 + 2];
                float h = boundingBoxes[k*4 + 3];

                int ix = (int)x;
                int iy = (int)y;
                int iw = (int)w;
                int ih = (int)h;
                
                // std::min not always available directly? Use algorithm or conditional.
                int radius = 10;
                if (iw/2 < radius) radius = iw/2;
                if (ih/2 < radius) radius = ih/2;
                
                int right = ix + iw;
                int bottom = iy + ih;
                
                for(int i = iy; i < bottom; i++) {
                    for(int j = ix; j < right; j++) {
                        // Bounds check (just in case)
                        if (i < 0 || i >= 240 || j < 0 || j >= 320) continue;
                        
                         // Check Rounded Corners
                        bool inside = true;
                        // Top-Left
                        if (j < ix + radius && i < iy + radius) {
                            if (pow(j - (ix + radius), 2) + pow(i - (iy + radius), 2) > pow(radius, 2)) inside = false;
                        }
                        // Top-Right
                        else if (j > right - radius && i < iy + radius) {
                            if (pow(j - (right - radius), 2) + pow(i - (iy + radius), 2) > pow(radius, 2)) inside = false;
                        }
                        // Bottom-Left
                        else if (j < ix + radius && i > bottom - radius) {
                            if (pow(j - (ix + radius), 2) + pow(i - (bottom - radius), 2) > pow(radius, 2)) inside = false;
                        }
                        // Bottom-Right
                        else if (j > right - radius && i > bottom - radius) {
                            if (pow(j - (right - radius), 2) + pow(i - (bottom - radius), 2) > pow(radius, 2)) inside = false;
                        }

                        if (inside) {
                            // Apply Multiply Blend
                            Vec4b &pixel = debugMat.at<Vec4b>(i, j);
                            pixel[0] = (pixel[0] * overlayColor[0]) / 255;
                            pixel[1] = (pixel[1] * overlayColor[1]) / 255;
                            pixel[2] = (pixel[2] * overlayColor[2]) / 255;
                            // Alpha pixel[3] check?
                        }
                    }
                }
            }
        }

        // platform_log("Set preprocess matrix");

        // start = std::chrono::high_resolution_clock::now();
        // duration = start.time_since_epoch();
        // microseconds = std::chrono::duration_cast<std::chrono::microseconds>(duration).count();
        // platform_log( (std::to_string(microseconds)+" ENDmicroseconds\n" ).c_str());
        // delete[] slicedImg;

        // Mat uframe, frame, grayFrame, xframe, leftFrame, rightFrame, bwframe;
        // Mat leftGrayFrame, rightGrayFrame;
        uframe.release();
        frame.release();
        grayFrame.release();
        xframe.release();
        leftFrame.release();
        rightFrame.release();
        bwframe.release();

        leftGrayFrame.release();
        rightGrayFrame.release();        
        #ifdef __EMSCRIPTEN__
            srcImageRgb.release();
        #endif
        // rawImageRgb.release();
        // matImageRgb.release();
        imageRgb.release();
        // return 0;
        return std::stoi("1"+leftFrameResult + rightFrameResult, nullptr, 2);        
    }

    FUNCTION_ATTRIBUTE
    int findColorInImageOld(uint8_t* img, uint32_t imgLength, uint8_t* lowerB, uint8_t* upperB, uint8_t colorSpace, uint8_t* imgMask) {
        vector<uint8_t> buffer(img, img + imgLength);
        Mat imageRgb;// = imdecode(buffer, IMREAD_COLOR);;

        Mat imageHsv, imageMask;
        cvtColor(imageRgb, imageHsv, COLOR_BGR2HSV);
        // inRange(imageHsv, lowerB, upperB, imgMask);
        // platform_log("CPP - findColorInImage\n");

        inRange(imageHsv, Scalar(lowerB[0], lowerB[1], lowerB[2]), Scalar(upperB[0], upperB[1], upperB[2]), imageMask);
        
        // platform_log(std::to_string(imageMask.rows).c_str());
        // platform_log("\n");
        // platform_log(std::to_string(imageMask.step).c_str());
        // platform_log("\n");

        int sum=0;
        sum = countNonZero(imageMask);
        // platform_log("SUM:\n");
        // platform_log(std::to_string(sum).c_str());
        // platform_log("\n");

        // unsigned char *input = (unsigned char*)(imageMask.data);
        // namedWindow("window_detection_name");
        // imshow("window_detection_name", imageMask);

        // uint8_t *output = (uint8_t*)(imageMask.data);
        // platform_log(std::to_string(sizeof(input)).c_str());
        // platform_log("\n");
        // uint32_t idx = 0;
        // for(int j = 0;j < imageMask.rows;j++){
        //     for(int i = 0;i < imageMask.cols;i++){
        //         unsigned char b = input[imageMask.step * j + i ] ;
        //         unsigned char g = input[imageMask.step * j + i + 1];
        //         unsigned char r = input[imageMask.step * j + i + 2];
        //         sum += (b+g+r);
        //         // imgMask[idx] = output[imageMask.step * j + i ] ;
        //         // imgMask[idx+1] = output[imageMask.step * j + i + 1] ;
        //         // imgMask[idx+2] = output[imageMask.step * j + i + 2] ;
        //         // idx+=3;
        //     }
        //     // if (sum > 0) return sum;
        // }        

        // vector<uchar> jpeg_data;
        // vector<int> params(2);
        // params[0] = IMWRITE_JPEG_QUALITY;
        // params[1] = 95; // Set the JPEG quality (0-100)
        // imencode(".jpg", imageMask, jpeg_data, params);
        // platform_log("Image Mask\n");
        // platform_log(std::to_string(jpeg_data.size()).c_str());
        // platform_log("\n");
        // char *chars = (char*)jpeg_data.data();
        // for (int i = 0; i < jpeg_data.size();i++){
        //     imgMask[i] = chars[i];
        // }
        // uint8_t *rawOutput = (uint8_t*)(imageRgb.data);
        // idx = 0;
        // for(int j = 0;j < imageRgb.rows;j++){
        //     for(int i = 0;i < imageRgb.cols;i++){
        //         imgMask[idx] = rawOutput[imageRgb.step * j + i ] ;
        //         imgMask[idx+1] = rawOutput[imageRgb.step * j + i + 1] ;
        //         imgMask[idx+2] = rawOutput[imageRgb.step * j + i + 2] ;
        //         idx+=3;
        //     }
        //     // if (sum > 0) return sum;
        // }        

        // for(int i = 0; i < imageMask.rows; i++)
        // {
        //     // std::string s = "";
        //     const double* Mi = imageMask.ptr<double>(i);
        //     for(int j = 0; j < imageMask.cols; j++){
        //         // sum += std::max(Mi[j], 0.);                
        //         // s=s + Mi[j] + " _ ";
        //         // if (Mi[j]==255){
        //         //     platform_log("Mask Detected White");
        //         //     return 1;
        //         // }
        //         // platform_log(std::to_string(Mi[j]).c_str());
        //     }
        //     // platform_log("asdasd");
        //     // sum += std::max(Mi[j], 0.);
        // }        
        // for (uint32_t i = 0;i<imgLength;i++){
        //     if (imgMask[i]==255){
        //         return 1;
        //     }
        // }
        return sum;

        // long long start = get_now();        
        // Mat input = imread(inputImagePath, IMREAD_GRAYSCALE);
        // Mat threshed, withContours;

        // vector<vector<Point>> contours;
        // vector<Vec4i> hierarchy;
        
        // adaptiveThreshold(input, threshed, 255, ADAPTIVE_THRESH_GAUSSIAN_C, THRESH_BINARY_INV, 77, 6);
        // findContours(threshed, contours, hierarchy, RETR_TREE, CHAIN_APPROX_TC89_L1);
        
        // cvtColor(threshed, withContours, COLOR_GRAY2BGR);
        // drawContours(withContours, contours, -1, Scalar(0, 255, 0), 4);
        
        // imwrite(outputImagePath, withContours);
    }

    // int evalInMillis = static_cast<int>(get_now() - start);
    // platform_log("Processing done in %dms\n", evalInMillis);    
// }





// This is a piece of MATLAB code that is used to find the largest connected component (blob) in an image and its centroid.
// Here’s a breakdown of what each line does:
// [i, j] = max(cellfun(@numel,blob.PixelIdxList));: This line finds the index of the largest connected component in the image. cellfun(@numel,blob.PixelIdxList) applies the numel function to each cell in blob.PixelIdxList (which contains the linear indices of each connected component in the image), returning an array of the sizes of each connected component. max then returns the size of the largest component (i) and its index (j).
// npx = i;: This line simply stores the size of the largest connected component in npx.
// [~, x] = ind2sub(blob.ImageSize, blob.PixelIdxList{j});: This line converts the linear indices of the largest connected component into subscripts relative to the size of the original image (blob.ImageSize). The ~ is used to ignore the row indices, while x stores the column indices, effectively giving the x-coordinates of the pixels in the largest connected component.
// So, in summary, this code is used to find the largest connected component in an image and its x-coordinates. It’s often used in image processing tasks such as object detection or segmentation. Please note that this explanation assumes some familiarity with MATLAB and image processing concepts. If you’re not familiar with these, you might need to look up some terms for a deeper understanding.


