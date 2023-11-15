import argparse as ap
from argparse import ArgumentDefaultsHelpFormatter, ArgumentParser
import io
import sys
import time
import serial
from serial import Serial
from tqdm import tqdm
import signal


def init_serial(port: str) -> Serial:
    """Opens PORT with 4800 8N1 settings and returns a Serial object."""
    try:
        return Serial(
            port,
            baudrate=4800,
            bytesize=8,
            parity="N",
            stopbits=1,
            timeout=2,
        )
    except serial.SerialException as e:
        print(f"Error while opening serial port: {e}")
        sys.exit(1)


def flash(ser: Serial, file: io.BufferedReader):
    program = file.read()
    length = len(program)
    print(f"Downloading file {file.name} length 0x{length:x} through {ser.port}")

    def wait():
        """Waits for device to be ready"""
        time.sleep(0.002)

    # Send "P" and program length
    ser.write("P".encode(encoding="ascii"))
    # ser.write(length.to_bytes(2, byteorder="big"))
    wait()

    program_progress_bar = tqdm(
        program,
        unit="B",
        unit_scale=True,
        unit_divisor=1024,
        ncols=40,
        bar_format="{n_fmt}{unit} {rate_fmt} {elapsed} [{bar}] {percentage:3.0f}% ",
    )
    for byte in program_progress_bar:
        ser.write(byte.to_bytes())
        wait()

        ack = ser.read(1).decode(encoding="ascii")
        if ack != "Z":
            print("Error: Device did not acknowledge")
            sys.exit(1)
        wait()


def main():
    parser = ArgumentParser(
        description="Program to download binary files to a device.",
        formatter_class=ArgumentDefaultsHelpFormatter,  # Print default values in help
    )
    parser.add_argument(
        "file",
        type=ap.FileType("rb"),
        help="The binary file to download",
    )
    parser.add_argument(
        "port",
        nargs="?",
        help="The port to which the device is connected",
        default=get_default_port(),
    )

    def sigint_handler(sig, frame):
        print("\nProgram interrupted by user")
        sys.exit(sig)

    signal.signal(signal.SIGINT, sigint_handler)

    args = parser.parse_args()
    ser = init_serial(args.port)
    flash(ser, args.file)

    args.file.close()
    ser.close()


def get_default_port():
    from serial.tools.list_ports import comports

    return comports()[0].device


if __name__ == "__main__":
    main()
