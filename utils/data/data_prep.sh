#!/bin/bash

# Copyright 2017 Xingyu Na
# Apache 2.0

./path.sh || exit 1;

if [ $# != 2 ]; then
  echo "Usage: $0 <Input:audio-path> <Output:train-dir> <Output:test-dir>"
  echo " $0 /export/a05/xna/data/data_aishell/wav data/train data/test"
  exit 1;
fi

audio_dir=$1
#aishell_text_dir=$2
output_train_dir=$2
output_test_dir=$3

train_dir=data/local/train
dev_dir=data/local/dev
test_dir=data/local/test

mkdir -p $train_dir
mkdir -p $dev_dir
mkdir -p $test_dir

# data directory check
if [ ! -d $audio_dir ] ; then
  echo "Error: $0 requires Input directory argument"
  exit 1;
fi

# find wav audio file for train, dev and test resp.
find $aishell_audio_dir -iname "*.wav" | grep -i "wav/train" > $train_dir/wav.flist || exit 1;
find $aishell_audio_dir -iname "*.wav" | grep -i "wav/dev" > $dev_dir/wav.flist || exit 1;
find $aishell_audio_dir -iname "*.wav" | grep -i "wav/test" > $test_dir/wav.flist || exit 1;

n=`cat $train_dir/wav.flist $dev_dir/wav.flist $test_dir/wav.flist | wc -l`
[ $n -ne 141925 ] && \
  echo Warning: expected 141925 data data files, found $n

# Transcriptions preparation
for dir in $train_dir $test_dir; do
  echo Preparing $dir transcriptions
  sed -e 's/\.wav//' $dir/wav.flist | awk -F '/' '{print $NF}' > $dir/utt.list
  sed -e 's/\.wav//' $dir/wav.flist | awk -F '/' '{i=NF-1;printf("%s %s\n",$NF,$i)}' > $dir/utt2spk_all
  paste -d' ' $dir/utt.list $dir/wav.flist > $dir/wav.scp_all
  awk '{print $1}' $dir/transcripts.txt | sort -u > $dir/utt.list
  utils/filter_scp.pl -f 1 $dir/utt.list $dir/utt2spk_all | sort -u > $dir/utt2spk
  utils/filter_scp.pl -f 1 $dir/utt.list $dir/wav.scp_all | sort -u > $dir/wav.scp
  #sort -u $dir/transcripts.txt > $dir/text
  utils/utt2spk_to_spk2utt.pl $dir/utt2spk > $dir/spk2utt
done

mkdir -p data/train data/test
for f in spk2utt utt2spk wav.scp; do
  cp $train_dir/$f $output_train_dir/$f || exit 1;
  cp $test_dir/$f $output_test_dir/$f || exit 1;
done

echo "$0: data preparation succeeded"
exit 0;
