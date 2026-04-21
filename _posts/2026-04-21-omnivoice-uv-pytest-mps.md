---
title: OmniVoice를 Apple Silicon MPS로 TTS 돌려보기
date: 2026-04-21 12:00:00 +0900
categories: [AI, TTS]
tags: [omnivoice, uv, mps, tts, apple-silicon]
description: k2-fsa/OmniVoice 리포를 uv로 동기화하고 MPS에서 TTS 샘플 6개를 뽑아본 기록이에요.
---

k2-fsa/OmniVoice가 나와서 Apple Silicon MPS에서 실제로 얼마나 돌아가는지 궁금했어요. uv로 환경 맞추고 샘플 몇 개 뽑는 데까지 해봤어요.

## 환경

| 항목 | 값 |
|------|-----|
| HW | Apple Silicon (arm64), 64 GB RAM |
| OS | macOS 26.3.1 build 25D771280a (Darwin 25.3.0) |
| 런타임 | Python 3.13.2, uv 0.11.6 |
| 주요 라이브러리 | torch 2.8.0, transformers 5.3.0, MPS available |
| 대상 리포 | `k2-fsa/OmniVoice` @ `4a4b2295d822c9ab96556c83fce467860519ea27` (branch `master`) |
| 메인 모델 | `k2-fsa/OmniVoice` 스냅샷 `292b2e0e846286f56e77caa9fffc7e8625ec9438`, `model.safetensors` 2.3 GB |
| 오디오 토크나이저 | 동일 스냅샷의 `audio_tokenizer/model.safetensors` 768 MB |
| 양자화 | 없음 (safetensors 원본) |
| HF 캐시 총합 | 3.0 GB |

> 코드상 오디오 토크나이저 fallback은 `eustlb/higgs-audio-v2-tokenizer`인데, 메인 스냅샷에 동봉돼 있어서 이번 세션에선 fallback이 안 탔어요.
{: .prompt-info }

## 설치·재현

리포에 `uv.lock`이 이미 들어 있어서 sync 한 방이면 끝이에요.

```bash
uv sync
```
{: .nolineno }

torch 2.8.0, torchaudio 2.8.0, transformers 5.3.0, gradio, pydub, librosa, soundfile, webdataset까지 쭉 깔려요. 저는 여기다가 수동으로 굴릴 플레이그라운드 스크립트 하나(`scripts/try_tts.py`)를 따로 만들어서 썼어요. 디바이스는 자동 감지(MPS/CUDA/CPU)하고, MPS/CPU는 fp32, CUDA는 fp16으로 돌리게 해뒀어요. `--case`로 단일 실행, `--device`/`--dtype`로 오버라이드돼요.

> README는 MPS에서 fp16을 권장하는데, 이번엔 스크립트 기본값인 fp32로만 돌렸어요. fp16 품질·속도 차이는 아직 안 봤어요.
{: .prompt-warning }

HF 모델 가중치는 첫 실행에서 자동으로 떨어져요. 캐시 총합 3.0 GB라 네트워크가 약한 환경이면 좀 기다려야 해요. (다운로드 소요 시간은 로깅 안 해둬서 수치로 못 남겼어요.)

## 실측 결과

6개 케이스를 한 번 돌려서 WAV로 떨궜어요.

| 파일 | 크기 | 추정 길이 (16-bit mono 24 kHz 가정) |
|------|------|------|
| `00_auto_en.wav` | 159,404 B | 약 3.32 s |
| `01_auto_ko.wav` | 163,244 B | 약 3.40 s |
| `02_design_female_british.wav` | 188,204 B | 약 3.92 s |
| `03_design_male_low.wav` | 161,324 B | 약 3.36 s |
| `04_design_whisper.wav` | 155,564 B | 약 3.24 s |
| `05_fast_inference.wav` | 138,284 B | 약 2.88 s |

샘플레이트/비트뎁스는 soundfile 기본 인코딩 가정이고, WAV 헤더를 직접 까서 검증하진 않았어요.

{% include embed/audio.html src='/assets/audio/omnivoice-uv-pytest-mps/00_auto_en.wav' title='00_auto_en — auto 모드, 영어' %}

{% include embed/audio.html src='/assets/audio/omnivoice-uv-pytest-mps/01_auto_ko.wav' title='01_auto_ko — auto 모드, 한국어' %}

{% include embed/audio.html src='/assets/audio/omnivoice-uv-pytest-mps/02_design_female_british.wav' title='02_design_female_british — voice design, female british' %}

{% include embed/audio.html src='/assets/audio/omnivoice-uv-pytest-mps/03_design_male_low.wav' title='03_design_male_low — voice design, male low' %}

{% include embed/audio.html src='/assets/audio/omnivoice-uv-pytest-mps/04_design_whisper.wav' title='04_design_whisper — voice design, whisper' %}

{% include embed/audio.html src='/assets/audio/omnivoice-uv-pytest-mps/05_fast_inference.wav' title='05_fast_inference — 빠른 추론 케이스' %}

영어(`00_auto_en`)는 꽤 자연스러운데, 한국어(`01_auto_ko`)는 톤이 많이 평평하고 억양이 어색한 느낌이 있어요. voice design 쪽은 `female_british`, `male_low`, `whisper` 모두 지정한 캐릭터가 어느 정도 구분돼 들리긴 해요.

## 한계·다음 할 일

- Voice cloning(`clone_my_voice` 케이스)은 제 ref_audio가 없어서 실행 안 했어요.
- `audio_chunk_duration` 기반 long-text 청킹 동작은 아직 확인 못 했어요.
- `num_step=16` vs `32` 품질·시간 비교는 동일 텍스트로 페어링해서 다시 돌려봐야 해요. 이번엔 16짜리 케이스 하나만 찍었어요.
- case별 생성 시간 / RTF 수치는 stdout에만 남았고 이 글에는 안 실었어요. 다음엔 표로 따로 정리할 생각이에요.
- WAV 헤더 실제 값(sample_rate, bit depth, mono/stereo)은 `soundfile.info`로 한 번 돌려서 붙이려고 해요.
- MPS fp16 실측은 아직 안 해봤어요.

## 참고 링크

- 대상 프로젝트: <https://github.com/k2-fsa/OmniVoice>
- 대상 커밋: <https://github.com/k2-fsa/OmniVoice/commit/4a4b2295d822c9ab96556c83fce467860519ea27>
- 메인 모델: <https://huggingface.co/k2-fsa/OmniVoice>
- 오디오 토크나이저 fallback: <https://huggingface.co/eustlb/higgs-audio-v2-tokenizer>
- uv: <https://github.com/astral-sh/uv>
