# PngCompressor

The PngCompressor project is essentially a port of the [libimagequant](https://github.com/ImageOptim/libimagequant/tree/2.x) library to the Zig programming language, featuring the use of Zig's C code interoperability feature to load and save images through the [LodePNG](https://github.com/lvandeve/lodepng) library. It also employs the [zig-clap](https://github.com/Hejsil/zig-clap) library for efficiently processing console arguments provided to the application. PngCompressor provides command-line options to reduce the file size of PNG images with minimal quality loss.

## Features
- Efficient compression of PNG images.
- Customizable options to control the input and output locations.
- Minimal quality loss thanks to the libimagequant library

## Installation

Building from source is pretty straightforward. Follow these steps:

1. Clone this repository to your local machine.

```
git clone https://github.com/GrainyTV/PngCompressor.git
```

2. Navigate to the repository's root directory.

```
cd PngCompressor
```

3. Compile the project by specifying the target CPU architecture and operating system. For example, to compile on a 64-bit Linux system with optimized settings, run:

```
zig build -Dtarget="x86_64-linux" -Doptimize=ReleaseFast
```

The build.zig file contains the necessary build instructions. The project should also work on Windows and macOS.

## Usage
PngCompressor is a command-line tool, and all interactions occur via command-line arguments. Currently, there are three available options:

`-i` `--input` : Specifies the input file or folder.

`-o` `--output`: Specifies the output file or folder.

`-f` `--force` : Allows overwriting the input files without specifying an output file or folder.

## Example Usage
To compress a single PNG file, you can use the following command:

```
./PngCompressor -i input.png -o output.png
```

To compress all PNG files in a folder and overwrite them, you can use the following command:

```
./PngCompressor -i ./my_folder -f
```

Note that you can also use absolute paths instead of relative ones if you prefer those.

## Screenshots
The images below demonstrate the quality of image compression achieved by PngCompressor. The left image shows the original, and the right image shows the compressed version. Not really noticeable unless you look very closely.

<table>
<thead>
  <tr>
    <th>Original Image</th>
    <th>Compressed Image</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>
    	<figure>
    		<img src="./example/example1.png" width="100%" />
  		<figcaption>2.1 MiB</figcaption>
	</figure>	
    </td>
    <td>
	<figure>
    		<img src="./example/example1_compressed.png" width="100%" />
  		<figcaption>701.1 KiB</figcaption>
	</figure>
    </td>
  </tr>
  <tr>
    <td colspan="2">1449.3 KiB reduction (≈ 67.40% smaller)</td>
  </tr>
    <tr>
    <td>
    	<figure>
    		<img src="./example/example2.png" width="100%" />
  		<figcaption>577.8 KiB</figcaption>
	</figure>	
    </td>
    <td>
	<figure>
    		<img src="./example/example2_compressed.png" width="100%" />
  		<figcaption>178 KiB</figcaption>
	</figure>
    </td>
  </tr>
  <tr>
    <td colspan="2">399.8 KiB reduction (≈ 69.19% smaller)</td>
  </tr>
    <tr>
    <td>
    	<figure>
    		<img src="./example/example3.png" width="100%" />
  		<figcaption>387.1 KiB</figcaption>
	</figure>	
    </td>
    <td>
	<figure>
    		<img src="./example/example3_compressed.png" width="100%" />
  		<figcaption>228.3 KiB</figcaption>
	</figure>
    </td>
  </tr>
  <tr>
    <td colspan="2">158.8 KiB reduction (≈ 41.02% smaller)</td>
  </tr>
</tbody>
</table>

## Contribution
I welcome contributions from anyone. If you have any observations, bug reports, or suggestions for improvements, please create issues or pull requests on this repository.

## License
PngCompressor is released under the MIT License. You are free to use, modify, and distribute the code in accordance with the terms of the license. See the [LICENSE](LICENSE) file for more details.
