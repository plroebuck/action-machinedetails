# GitHub Action - Display Machine Details
Displays basic machine information for macOS

## Inputs

### `show_hardware`

Optional. Displays basic hardware information [true, false]

### `show_hardware`

Optional. Displays basic software information [true, false]

### `show_environment`

Optional. Displays environment variables. [true, false]

## Example usage

```yml
jobs:
  do-something:
    runs-on: macos-latest # [macos-13, macos-14, macos-15]

  steps:
    - name: Grab machine details
      uses: plroebuck/action-machinedetails@v1
      with:
        show_hardware: true      # optional
        show_software: true      # optional
        show_environmen: true    # optional
```
