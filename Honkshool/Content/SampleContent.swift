enum SampleContent {
  static let journeyTitle = "How a Car Works"
  static let sessionTitle = "Turning Fuel Into Motion"

  // This short, provisional script exists only to exercise speech and audio
  // behavior. It is not the researched session intended for the content catalog.
  static let narration = """
    A car engine is a machine for turning stored energy into controlled motion.

    Inside each cylinder, the engine draws in air and fuel. The piston compresses that mixture into a smaller space. A spark begins a fast, controlled burn, and the expanding gases push the piston down.

    The piston moves in a straight line, but the wheels need rotation. A connecting rod links the piston to the crankshaft. As the piston moves down, the rod turns the crankshaft, much like pushing on the pedal of a bicycle turns its crank.

    One cylinder cannot provide perfectly steady motion by itself. Several cylinders take turns producing power. The crankshaft gathers those separate pushes into a smoother rotation, and the flywheel helps carry momentum between them.

    From there, the transmission adjusts the relationship between engine speed and wheel speed. Lower gears trade speed for more turning force. Higher gears let the car travel farther for each turn of the engine.

    For this short test, the useful idea is simple. Combustion pushes pistons. Connecting rods turn a crankshaft. The transmission shapes that rotation, and the tires finally press against the road.
    """
}
