---
title: OmniVoice로 3초 음성 복제해보기
date: 2026-04-21 14:00:00 +0900
categories: [Dev, TTS]
tags: [OmniVoice, TTS, 음성 복제, 벤치마크, Apple Silicon, MPS]
description: 내 목소리 7초 녹음 하나로 10개 언어 cross-lingual 클로닝, 비언어 태그, RTF 벤치까지 Apple Silicon MPS에서 돌려본 기록
---

1차 세션에선 디자인 프리셋만 찍어봤는데, "3초 녹음으로 600개 언어에 내 목소리를 복제한다"는 주장 쪽을 직접 확인하고 싶었어요. 제가 직접 녹음한 ref 한 개를 입력으로 주고, 멀티링구얼 클로닝·비언어 태그(`[laughter]` 등)·RTF 벤치까지 이어서 돌려봤어요.

## 환경

1차 세션과 같은 머신·캐시·커밋이에요.

| 항목 | 값 |
|------|-----|
| HW | Apple Silicon (arm64), 64 GB RAM |
| OS | macOS 26.3.1 |
| 런타임 | Python 3.13.2, uv 0.11.6, torch 2.8.0 (MPS), transformers 5.3.0 |
| 추가 도구 | ffmpeg 7.1.1 (Homebrew) |
| 대상 리포 | `k2-fsa/OmniVoice` @ `4a4b2295d822c9ab96556c83fce467860519ea27` |
| 모델 | `k2-fsa/OmniVoice` 스냅샷 `292b2e0e846286f56e77caa9fffc7e8625ec9438` |
| 양자화 | 없음 (safetensors fp32, MPS 커널 이슈 피해서 fp16 안 씀) |
| ref 원본 | `옴니보이스.m4a` / AAC 128kbps / 48 kHz mono / 7.42 s |
| ref 정규화 후 | `chaeminu_ref.wav` / PCM_16 / 24 kHz mono / 7.42 s / peak −3.17 dBFS |

## 설치·재현

### ref 녹음 정규화

원본 m4a는 제가 폰으로 녹음한 거예요. 48 kHz / −25 dB 평균 / −6.1 dB 피크라 살짝 작아서 +3 dB 게인 주고 24 kHz mono PCM_16으로 변환했어요.

```bash
ffmpeg -hide_banner -y -i scripts/refs/옴니보이스.m4a -af "volume=3dB" \
  -ar 24000 -ac 1 -c:a pcm_s16le scripts/refs/chaeminu_ref.wav
```
{: .nolineno }

변환 후 `soundfile.info`로 재검증하니 24 kHz mono PCM_16 / 7.42 s / peak −3.17 dBFS / RMS −21.99 dBFS로 찍혔어요.

{% include embed/audio.html src='/assets/audio/omnivoice-cloning-rtf-bench/ref_chaeminu.wav' title='ref_chaeminu — 입력으로 준 제 목소리 7.42초' %}

### 세 가지 러너 스크립트

1차 세션의 `try_tts.py`를 바탕으로 세 개로 쪼갰어요. `test_clone_multilingual.py`(단일 ref + 10개 언어), `test_nonverbal.py`(`[laughter]/[sigh]` 태그·발음 교정·클로닝 결합 10케이스), `bench_rtf.py`(mode × num_steps × warmup/runs RTF 측정).

처음 `--help` 돌릴 땐 `ModuleNotFoundError: No module named 'omnivoice'`가 떴어요. 1차 세션에서 `pyproject.toml`을 건드린 뒤 editable 링크가 일시적으로 깨진 걸로 보여서, `uv run --reinstall`로 한 번 강제 재설치하니까 복구됐어요.

```bash
uv run --reinstall python -c "import omnivoice; print(omnivoice.__file__)"
```
{: .nolineno }

그 뒤로는 세 스크립트 모두 정상이에요.

```bash
uv run python scripts/test_clone_multilingual.py 2>&1 | tee scripts/out/clone/run.log
uv run python scripts/test_nonverbal.py 2>&1 | tee scripts/out/nonverbal/run.log
uv run python scripts/bench_rtf.py --csv scripts/out/bench/timings.csv 2>&1 | tee scripts/out/bench/run.log
```

## 실측 결과

### 멀티링구얼 클로닝 (ref 1개 → 10개 언어)

같은 한국어 ref 하나로 10개 언어 타겟 텍스트를 생성했어요. 워밍업 없이 1회씩이라 RTF 분산은 크다고 보면 돼요.

| # | language | dur (s) | gen (s) | RTF |
|---|---|---:|---:|---:|
| 0 | Korean (control) | 4.64 | 8.55 | 1.843 |
| 1 | English | 4.92 | 6.54 | 1.330 |
| 2 | Japanese | 7.52 | 8.00 | 1.064 |
| 3 | Chinese | 6.12 | 7.58 | 1.239 |
| 4 | French | 5.52 | 7.17 | 1.299 |
| 5 | German | 5.52 | 7.09 | 1.284 |
| 6 | Spanish | 5.44 | 6.95 | 1.277 |
| 7 | Vietnamese | 4.80 | 6.74 | 1.404 |
| 8 | Standard Arabic | 5.16 | 6.83 | 1.324 |
| 9 | Hindi | 4.60 | 7.17 | 1.559 |

> 클로닝 모드 RTF는 전부 1.0을 넘어요. MPS + fp32 + num_step=32 조합에서는 리얼타임 미달이에요.
{: .prompt-info }

청취 결과부터요. 한국어(same-language) 클로닝은 초반이 약간 어색한데 뒤로 갈수록 자연스러워졌어요. 제가 제일 놀란 건 영어 쪽인데, 제 영어 발음 버릇이랑 목소리 톤이 너무 비슷하게 나와서 소름이 돋을 정도였어요. 나머지 cross-lingual 7개(일본어·중국어·프랑스어·독일어·스페인어·베트남어·아랍어·힌디어)는 해당 언어를 제대로 판단할 수 있는 청자가 없어서 검증 보류예요.

{% include embed/audio.html src='/assets/audio/omnivoice-cloning-rtf-bench/clone_00_korean_control.wav' title='clone/00_korean_control — 같은 한국어 ref 그대로 같은 언어로 복제' %}

{% include embed/audio.html src='/assets/audio/omnivoice-cloning-rtf-bench/clone_01_english.wav' title='clone/01_english — 한국어 ref 하나로 영어 크로스링구얼 클로닝' %}

### 비언어 태그 + 발음 교정 (10 케이스)

auto 모드에서 문장 중간에 `[laughter]`, `[sigh]` 같은 태그를 넣어봤고, design 모드로 성별·톤을 지정한 뒤 웃음을 얹어봤고, English CMU / Chinese pinyin 발음 교정도 돌려봤고, 제 한국어·영어 목소리 클로닝에 비언어 태그를 결합해봤어요.

| # | name | dur (s) | gen (s) | RTF |
|---|---|---:|---:|---:|
| 0 | auto_laughter_mid | 3.76 | 2.59 | 0.690 |
| 1 | auto_sigh_start | 2.24 | 1.94 | 0.868 |
| 2 | auto_surprise_oh | 3.44 | 2.31 | 0.670 |
| 3 | auto_dissatisfaction | 3.36 | 2.22 | 0.659 |
| 4 | design_female_laughter | 3.36 | 2.30 | 0.686 |
| 5 | english_cmu_bass | 2.99 | 2.59 | 0.868 |
| 6 | chinese_pinyin_zhe_she | 5.85 | 3.42 | 0.585 |
| 7 | clone_korean_laughter | 3.76 | 6.15 | 1.636 |
| 8 | clone_korean_sigh | 2.64 | 5.38 | 2.037 |
| 9 | clone_english_laughter | 4.48 | 6.93 | 1.547 |

auto/design은 RTF 0.585–0.868로 1 이하인데, 클로닝이 끼는 순간 1.5–2.0대로 뛰어요. ref attention이 들어가는 게 비싸다는 거겠죠.

auto 모드 `[laughter]`는 실제로 문장 중간에 웃음이 섞여 나왔어요.

{% include embed/audio.html src='/assets/audio/omnivoice-cloning-rtf-bench/nonverbal_00_auto_laughter_mid.wav' title='nonverbal/00_auto_laughter_mid — auto 모드 [laughter] 정상 발화' %}

English CMU 발음 교정은 같은 "bass" 단어에 대해 CMU 기호 주석 여부로 발음이 바뀌는지 확인용이었는데, 실제로 두 샘플의 발음이 다르게 나왔어요.

{% include embed/audio.html src='/assets/audio/omnivoice-cloning-rtf-bench/nonverbal_05_english_cmu_bass.wav' title='nonverbal/05_english_cmu_bass — CMU 주석 유/무에 따른 bass 발음 차이' %}

문제는 제 목소리 클로닝 + 한국어 + `[laughter]` 조합이에요. 웃음이 안 나와요.

{% include embed/audio.html src='/assets/audio/omnivoice-cloning-rtf-bench/nonverbal_07_clone_korean_laughter.wav' title='nonverbal/07_clone_korean_laughter — 클로닝+한국어+[laughter] 조합, 웃음 미발화' %}

> auto 모드에서 같은 `[laughter]` 패턴은 정상 작동해요. ref_audio가 들어가는 순간 비언어 토큰이 가려지는 것으로 추정되는데, 원인은 아직 못 잡았어요.
{: .prompt-warning }

소스 코드를 좀 파봤어요. `omnivoice/models/omnivoice.py`의 `_NONVERBAL_PATTERN`(1508)에 `laughter` 포함 13개 태그가 정규식으로 등록돼 있고, `_tokenize_with_nonverbal_tags`(1515)가 패턴별로 standalone 토큰화를 해요. `_build_inputs`(~1060)에서 `_combine_text(ref_text, text)`(1555) 결과를 통째로 그 토크나이저에 넘겨요. `_combine_text`는 `ref_text + " " + text`로 단순 결합이라 태그가 이 단계에서 사라지진 않을 거예요. 다만 클로닝 모드는 `ref_audio_tokens`이 디코더 conditional input에 프리픽스로 붙는데(~1112), 이 가이던스가 비언어 토큰을 어텐션에서 우세하게 덮는 게 아닐까 싶어요. 검증은 아직이에요.

### RTF 벤치 (warmup 1 + runs 3)

단일 영어 prompt로 mode × num_steps 6조합을 각각 3회씩 측정했어요.

| mode | num_step | audio dur | gen median | gen min | gen max | RTF median | speedup |
|---|---:|---:|---:|---:|---:|---:|---:|
| auto | 16 | 7.31 s | 2.29 s | 2.28 s | 2.39 s | 0.313 | 3.19× |
| auto | 32 | 7.62 s | 4.21 s | 4.17 s | 4.46 s | 0.552 | 1.81× |
| design | 16 | 7.30 s | 2.42 s | 2.36 s | 2.47 s | 0.331 | 3.02× |
| design | 32 | 7.19 s | 4.72 s | 4.61 s | 4.86 s | 0.656 | 1.52× |
| clone | 16 | 8.88 s | 5.61 s | 5.22 s | 5.65 s | 0.631 | 1.58× |
| clone | 32 | 8.88 s | 10.21 s | 10.10 s | 10.36 s | 1.150 | 0.87× |

README의 "실시간보다 40× 빠르다"(RTF ≈ 0.025)는 CUDA + fp16 기준이에요. 제 환경에서 최고값은 auto/n=16의 0.313이라 약 12.5배 차이가 나요. clone/n=32 조합은 0.87×로 아예 리얼타임 미달이에요.

> 이 수치는 MPS + fp32 기준이에요. README 권장 설정(CUDA + fp16)이나 MPS + fp16은 아직 안 재봤어요.
{: .prompt-info }

## 한계·다음 할 일

- clone 02–09(일본어·중국어 등 7개 언어) 본인 목소리 cross-lingual 결과는 해당 언어 네이티브 화자의 청취 검증이 필요해요. 숫자는 떨어졌지만 품질 판단은 보류예요.
- `[laughter]` 미작동 원인은 아직 확정 못 했어요. ref_audio 프리픽스가 비언어 토큰을 어텐션에서 마스킹하는지 디버그 로그로 확인 예정이에요.
- MPS + fp16은 안 돌렸어요. 커널 이슈 회피용으로 fp32로 통일했는데, fp16에서 RTF가 얼마나 떨어지는지는 다음에 볼 거예요.
- num_step=64, guidance_scale, t_shift 스윕은 아직이에요.
- `audio_chunk_duration` 기반 long-text 청킹도 아직 안 돌려봤어요.
- ref 길이(3초 vs 7초 vs 10초)에 따른 클로닝 품질 차이도 비교 대상이에요.

## 참고 링크

- 대상 프로젝트: <https://github.com/k2-fsa/OmniVoice>
- 대상 커밋: <https://github.com/k2-fsa/OmniVoice/commit/4a4b2295d822c9ab96556c83fce467860519ea27>
- 모델: <https://huggingface.co/k2-fsa/OmniVoice>
- 1차 세션 포스트: [OmniVoice를 Apple Silicon MPS로 TTS 돌려보기]({% post_url 2026-04-21-omnivoice-uv-pytest-mps %})
