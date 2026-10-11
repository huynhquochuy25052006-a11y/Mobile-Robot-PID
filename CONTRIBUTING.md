# Contributing

This repository is being prepared for its initial MATLAB/Simulink models and ESP32 firmware release.

## Reporting an issue

Describe the expected behavior, actual behavior, and steps to reproduce it. Include the MATLAB release and toolboxes, or the ESP32 board and toolchain, as appropriate. For control-related issues, include sample time, units, encoder counting mode, controller settings, and a minimal example or relevant plot.

## Adding models, firmware, or data

- Follow the proposed directory layout in the README.
- Document units, coordinate conventions, model assumptions, and entry points.
- State which results come from simulation and which come from hardware.
- Include the sample period and discretization method with PID coefficients.
- Describe data columns, timestamps, measurement conditions, and preprocessing.
- Commit source files and reproducibility settings; omit generated build output.
- Check that uploads contain no credentials, private information, or third-party material you are not allowed to publish.

For changes to a control algorithm, provide a reproducible comparison with the previous behavior. Documentation-only changes do not require a hardware test.

## Licensing

The owner has not selected a project license yet. Discuss licensing with the owner before submitting third-party code or material with reuse restrictions.
