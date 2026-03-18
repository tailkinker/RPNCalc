# RPNCalc

**A fast, lightweight Reverse Polish Notation calculator built with Lazarus and Free Pascal.**

RPNCalc is a desktop calculator designed for users who prefer the efficiency of RPN (postfix notation). By eliminating the need for parentheses, it allows for faster complex calculations and provides a clear view of the evaluation stack.

---

## 🚀 Features

* **RPN Engine:** Efficiently handle complex expressions without parentheses.
* **Visual Stack:** See exactly what is on the stack at any given time.
* **Native Performance:** Built with Free Pascal for high speed and low memory usage.
* **Standalone Binary:** No heavy dependencies or installers required for Linux.

---

## 🛠 Getting Started

### Prerequisites
* **Lazarus:** the Free Pascal RAD IDE.  If you can run Lazarus on your platform, you can compile this code.

### Installation
You can run the standalone binary immediately if you are running a 64-bit Linux distribution.

1.  Download the latest release from the [Releases](https://github.com/tailkinker/RPNCalc/releases) page.
2.  Open your terminal and navigate to the download folder.
3.  Give the file execution permissions:
    ```bash
    chmod +x rpncalc
    ```
4.  Run the application:
    ```bash
    ./rpncalc
    ```

### Building from Source
To compile the project yourself, you will need the **Lazarus IDE**:

1.  Clone the repository:
    ```bash
    git clone [https://github.com/tailkinker/RPNCalc.git](https://github.com/tailkinker/RPNCalc.git)
    ```
2.  Open Lazarus.
3.  Go to **Project > Open Project** and select `rpncalc.lpi`.
4.  Press **F9** to build and run.
5.  Alternately, run **lazbuild rpncalc.lpi** in the source directory.

---

## 📜 License
Distributed under the GNU GPL v3 License. See `LICENSE` for more information.

**Author:** [tailkinker](https://github.com/tailkinker)
