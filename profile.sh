sudo HOME=/tmp ncu --set full \
    --section-folder $NCU_SECTION_FOLDER \
    -o profile_report \
    -f \
    ./build/cuda/matrix_inversion_6.out --time \
    ./data/input/matrix_0_5120 \
    ./data/input/matrix_1_5120

