# QCanvas2D Graphics Library

QCanvas2D is a lightweight 2D graphics library for creating and manipulating graphical elements on a canvas. It provides a simple and intuitive API for drawing shapes, text, and images, as well as handling user input and animations.

## Description

QCanvas2D is a 2D graphics canvas library built using Tcl/Tk and leveraging OpenGL for rendering via the Togl widget. Its primary purpose is to provide a platform for creating graphical applications.

The library appears to be authored by Philip Quaife, with some code dating back to 2005/2006.

## Key Components & Features

*   **`qCanvas.tcl`**: This is the main driver for the canvas. It handles canvas creation, event management, and rendering logic.
*   **`primatives.qgl`**: A library that provides procedures for drawing a variety of graphical primitives, including:
    *   Rectangles
    *   Ovals and Arcs
    *   Lines and Polygons
    *   Text rendering (potentially with FTGL for TrueType fonts)
    *   Basic 3D shapes like Cubes and Teapots
*   **OpenGL Acceleration**: Utilizes Togl to leverage OpenGL for hardware-accelerated 2D graphics.
*   **Color & Basic Styling**: Supports fill and outline colors for shapes.
*   **Transformations**: The code suggests capabilities for scaling and rotation.
*   **Image Support**: Includes functionality for image display, potentially with tiling.
*   **Display Lists**: Uses OpenGL display lists for efficient rendering of grouped objects.

## File Structure

The project primarily consists of Tcl/Tk scripts and graphics library files:

*   **`*.tcl` / `*.tk` files**: These are the core Tcl/Tk scripts that define the canvas functionality, user interface elements (if any), and application logic.
    *   `qCanvas.tcl`: The main canvas driver.
    *   `userargs.tk`: A utility for command-line argument parsing.
    *   Other `.tk` files likely handle specific aspects like bindings, fonts, canvas functions, etc.
*   **`*.qgl` files**: These files contain graphics library definitions, specifically for drawing primitives.
    *   `primatives.qgl`: Defines various 2D and basic 3D shapes.
*   **`Splash.gif`**: A GIF image, likely used as a splash screen or an asset within an application.

## Potential Usage

Based on comments found within `primatives.qgl` (mentioning "QCanvas2D - Qanim - QMines -QBattleships"), this library could serve as a foundation for 2D graphical applications such as:

*   Simple animations (`Qanim`)
*   Basic 2D games (e.g., `QMines`, `QBattleships`)
*   Custom data visualization tools
*   Educational software requiring graphical output

## Getting Started / How to Run

The specific entry point or example scripts to run a full application using QCanvas2D are not present in the current set of files. It is a library that provides graphics capabilities, and demo code or complete applications that utilize it would need to be developed separately.

To use this library, you would typically:
1.  Source the `qCanvas.tcl` script within your Tcl/Tk application.
2.  Utilize the procedures defined by QCanvas2D to create a canvas and draw graphical elements.

## Dependencies

This library requires the following to be installed:

*   **Tcl/Tk**: As a Tcl/Tk application, a working Tcl/Tk environment is essential.
*   **Togl**: An OpenGL widget for Tk. This is crucial for the rendering capabilities of QCanvas2D.
*   **tcl3d**: The code explicitly requires `package require tcl3d`.
*   **FTGL**: The code checks `if {[tcl3dHaveFTGL]}` suggesting FTGL (OpenGL Font Rendering Library) is an optional dependency, likely for TrueType font support.
*   **zlib**: The code checks `if {! [catch {package require zlib}] }`, indicating zlib is an optional dependency, possibly for compressed font file support (`.qfnt`).
