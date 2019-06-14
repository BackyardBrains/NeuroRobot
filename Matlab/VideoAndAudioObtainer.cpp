//
//  Created by Djordje Jovic on 11/5/18.
//  Copyright © 2018 Backyard Brains. All rights reserved.
//

#include "MexThread.h"
#include "Macros.h"
#include "SharedMemory.cpp"
#include "Log.cpp"

#include <iostream>

//// FFMPEG includes
extern "C" {
    #include <libavcodec/avcodec.h>
    #include <libavformat/avformat.h>
    #include <libavformat/avio.h>
    #include <libswscale/swscale.h>
    #include <libavutil/imgutils.h>
}

/**
 Derived class.
 Reads video and audio data from RAK5206 and saves data to shared memory
 */
class VideoAndAudioObtainer : public MexThread, public Log {

private:
    AVFormatContext* format_ctx = avformat_alloc_context();
    AVCodecContext* videoCodec_ctx = NULL;
    struct SwsContext* img_convert_ctx = nullptr;
    int video_stream_index = 0;
    int audio_stream_index;
    int openInput = -1;

    AVPacket packet;
    AVCodec* videoCodec = NULL;
    AVFrame* picture = av_frame_alloc();
    AVFrame* picture_rgb = av_frame_alloc();
    int cnt = 0;

    SharedMemory* sharedMemoryInstance;

    // >>>>>>>>>>>>>>>>>> AUDIO <<<<<<<<<<<<<<<<<<
    AVCodec* audioCodec = NULL;
    AVCodecContext* audio_dec_ctx = NULL;
    // >>>>>>>>>>>>>>>>>> AUDIO <<<<<<<<<<<<<<<<<<

    //     std::chrono::time_point<std::chrono::steady_clock> lastTime =
    //     std::chrono::high_resolution_clock::now();

public:
    //-----------------------------------
    // Init methods.
    VideoAndAudioObtainer(SharedMemory* sharedMemory, std::string ipAddress)
    {
        className = "VideoAndAudioObtainer";
        sharedMemoryInstance = sharedMemory;
        openStreams();

        //// Register everything
        av_register_all();
        avformat_network_init();

        //// Open RTSP
        std::string url = std::string();
        url.append("rtsp://admin:admin@");
        url.append(ipAddress);
        url.append("/cam1/h264");
        AVDictionary* stream_opts = 0;
        // av_dict_set(&stream_opts, "timeout", "10000000", 0); // in microseconds.
        av_dict_set(&stream_opts, "rtp", "write_to_source", 0); // write_to_source
        openInput = avformat_open_input(&format_ctx, url.c_str(), NULL, &stream_opts);

        if (openInput != 0) {

            logMessage("init >>> not succeeded 'avformat_open_input'");
            return;
        }

        if (avformat_find_stream_info(format_ctx, NULL) < 0) {

            logMessage("init >>> not succeeded 'avformat_find_stream_info");
            return;
        }

        //// Search video stream
        for (int i = 0; i < format_ctx->nb_streams; i++) {
            if (format_ctx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
                video_stream_index = i;
            } else if (format_ctx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_AUDIO) {
                audio_stream_index = i;
            }
        }

        av_init_packet(&packet);
        packet.data = NULL;
        packet.size = 0;

        // >>>>>>>>>>>>>>>>>> VIDEO <<<<<<<<<<<<<<<<<<
        //// Start reading packets from stream
        av_read_play(format_ctx);

        //// Get the codec
        videoCodec = avcodec_find_decoder(AV_CODEC_ID_H264);
        if (!videoCodec) {
            exit(1);
        }

        //// Add this to allocate the context by codec
        videoCodec_ctx = avcodec_alloc_context3(videoCodec);

        AVCodecParameters* par = avcodec_parameters_alloc();
        avcodec_get_context_defaults3(videoCodec_ctx, videoCodec);
        AVCodecContext* pCodecCtx2 = format_ctx->streams[video_stream_index]->codec;
        AVCodec* pCodec = avcodec_find_decoder(
            format_ctx->streams[video_stream_index]->codecpar->codec_id);
        AVCodecContext* pCodecCtx = avcodec_alloc_context3(pCodec);

        avcodec_parameters_from_context(par, pCodecCtx2);
        avcodec_parameters_to_context(videoCodec_ctx, par);
        avcodec_parameters_free(&par);
        avcodec_free_context(&pCodecCtx);

        if (avcodec_open2(videoCodec_ctx, videoCodec, NULL) < 0)
            exit(1);

        int size2 = av_image_get_buffer_size(
            AV_PIX_FMT_BGR24, videoCodec_ctx->width, videoCodec_ctx->height, 1);
        uint8_t* picture_buffer_2;
        picture_buffer_2 = (uint8_t*)(av_malloc(size2));
        av_image_fill_arrays(picture_rgb->data, picture_rgb->linesize,
            picture_buffer_2, AV_PIX_FMT_BGR24,
            videoCodec_ctx->width, videoCodec_ctx->height, 1);
        av_free(picture_buffer_2);

        // >>>>>>>>>>>>>>>>>> VIDEO <<<<<<<<<<<<<<<<<<

        // >>>>>>>>>>>>>>>>>> AUDIO <<<<<<<<<<<<<<<<<<

        audioCodec = avcodec_find_decoder(AV_CODEC_ID_PCM_ALAW);
        if (!audioCodec) {
            exit(1);
        }
        // Add this to allocate the context by codec
        audio_dec_ctx = avcodec_alloc_context3(audioCodec);

        AVCodecParameters* par2 = avcodec_parameters_alloc();
        avcodec_get_context_defaults3(audio_dec_ctx, audioCodec);
        AVCodecContext* pCodecCtx22 = format_ctx->streams[audio_stream_index]->codec;
        AVCodec* pCodec2 = avcodec_find_decoder(
            format_ctx->streams[audio_stream_index]->codecpar->codec_id);
        AVCodecContext* pCodecCtx11 = avcodec_alloc_context3(pCodec2);

        avcodec_parameters_from_context(par2, pCodecCtx22);
        avcodec_parameters_to_context(audio_dec_ctx, par2);
        avcodec_parameters_free(&par2);
        avcodec_free_context(&pCodecCtx11);

        if (avcodec_open2(audio_dec_ctx, audioCodec, NULL) < 0)
            exit(1);

        // >>>>>>>>>>>>>>>>>> AUDIO <<<<<<<<<<<<<<<<<<
        
        logMessage("init >>> done");
    }

    //-----------------------------------
    // Overloaded methods.
    void run()
    {
        if (openInput != 0) {
            logMessage("run >>> Input not opened");
            return;
        }

        uint8_t* rgb_data[8];

        for (int i = 0; i < 1; i++) {

            logMessage("frameSize: " + std::to_string(sharedMemoryInstance->frameSize));

            rgb_data[i] = (uint8_t*)malloc(sharedMemoryInstance->frameSize);
        }
        
        while (av_read_frame(format_ctx, &packet) >= 0 && isRunning()) {
            
            if (packet.stream_index == video_stream_index) { // packet is video
                logMessage("run >>> video packet");
                int check = 0;

                decode(videoCodec_ctx, picture, &check, &packet);

                if (check != 0) {
                    img_convert_ctx = sws_getCachedContext(
                        img_convert_ctx, videoCodec_ctx->width, videoCodec_ctx->height,
                        videoCodec_ctx->pix_fmt, videoCodec_ctx->width,
                        videoCodec_ctx->height, AV_PIX_FMT_BGR24, SWS_BICUBIC, NULL, NULL,
                        NULL);
                    sws_scale(img_convert_ctx, picture->data, picture->linesize, 0,
                        videoCodec_ctx->height, rgb_data, picture_rgb->linesize);

                    sharedMemoryInstance->writeFrame(rgb_data[0]);
                    //                     av_packet_unref(&packet);
                    //                     sws_freeContext(img_convert_ctx);
                }
                cnt++;
            } else if (packet.stream_index == audio_stream_index) {
                /* decode audio frame */
                logMessage("run >>> audio packet");
                int ret = 0;

                int decoded = packet.size;

                avcodec_send_packet(audio_dec_ctx, &packet);
                ret = avcodec_receive_frame(audio_dec_ctx, picture);
                if (ret < 0) {
                    break;
                }
                decoded = FFMIN(ret, packet.size);
                if (ret == 0) {
                    sharedMemoryInstance->writeAudio(picture->extended_data[0]);
                }
            }
            //            av_free_packet(&packet);
            av_packet_unref(&packet);
            av_init_packet(&packet);
        }
        logMessage("End of run()");
        //         avformat_close_input(&format_ctx);
        free(rgb_data[0]);
        freeAllObjects();
    }

    //----------------------------------
    // Rest of the methods.
    int decode(AVCodecContext* avctx, AVFrame* frame, int* got_frame, AVPacket* pkt)
    {
        int ret;

        *got_frame = 0;

        if (pkt) {
            ret = avcodec_send_packet(avctx, pkt);
            // In particular, we don't expect AVERROR(EAGAIN), because we read all
            // decoded frames with avcodec_receive_frame() until done.
            if (ret < 0)
                return ret == AVERROR_EOF ? 0 : ret;
        }

        ret = avcodec_receive_frame(avctx, frame);

        if (ret < 0 && ret != AVERROR(EAGAIN) && ret != AVERROR_EOF)
            return ret;
        if (ret >= 0)
            *got_frame = 1;

        return 0;
    }

    void freeAllObjects()
    {
        stop();
        sharedMemoryInstance->blockWritters();
        logMessage("freeAllObjects >>> entered");
        closeStreams();

        try {
            av_packet_unref(&packet);
            av_free(picture);
            av_free(picture_rgb);
            av_read_pause(format_ctx);
            sws_freeContext(img_convert_ctx);
            avformat_close_input(&format_ctx);

        } catch (...) {

            logMessage("freeAllObjects >>>  catched error");
        }

        format_ctx = NULL;
        videoCodec_ctx = NULL;
        openInput = -1;
    }
};
