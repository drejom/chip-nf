process index {
  """
  gem-indexer -i {genome} -o ${genome_pref} -T ${cpus} -m ${memory}
  """
}

process mapping {
  script:
  cat = { 'zcat' if fastq }
  command = ""
  command += "${cat} ${fastq} | gem-mapper -I ${index} -q ${quality} -T ${cpus} | pigz -p ${cpus} -c ${_ctx.input} > ${_ctx.output|ext}.map.gz"
  command += "gt.filter -i ${map} --max-levenshtein-error ${_ctx.mism} -t ${cpus}| gt.filter --max-matches $((${_ctx.hits}+1)) -t ${cpus} | pigz -p ${cpus} -c > ${_ctx.output|ext}.filter.map.gz"
  command += "pigz -p ${cpus} -dc ${filtered} | gem-2-sam -T ${cpus} -I ${index} -q ${quality} -l --expect-single-end-reads | awk 'BEGIN{OFS=FS=\"\\t\"}$0!~/^@/{split(\"1_2_8_32_64_128\",a,\"_\");for(i in a){if(and($2,a[i])>0){$2=xor($2,a[i])}}}{print}\'") | samtools view -@ ${cpus} -Sb - | samtools sort -@ ${cpus} - ${_ctx.output} > ${_ctx.output}"
  command += "samtools view -@ ${cpus} -bF256 ${bam}  > ${bam}_primary.bam"
  """
}

process model {
  """
  run_spp.R -c=${bam} -rf -out=${prefix}.params.out -savp=${prefix}.pdf -p=${cpus}
  """
}

process peak {
  script:
  broad = { '--broad' if peak in broad_peaks else ''}
  command = ""
  command += "macs2 callpeak -t ${bam} -n ${prefix} --gsize hs -c ${chip_input} --nomodel --shiftsize=half_fragment_size ${broad}"
  """
}

process wiggle {

}
