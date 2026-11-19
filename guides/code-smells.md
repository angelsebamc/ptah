# Code smells

The smells the Standards reviewer looks for in changed code, from Martin Fowler's *Refactoring*, chapter 3.

Report a smell only where the change introduces it or makes it worse. The fix column is what to write on the finding's `Fix:` line, made concrete for the code at hand.

| Smell | What it looks like | Fix |
|---|---|---|
| **Mysterious Name** | A function, variable, or type whose name doesn't say what it does or holds | Rename it to say what it does or holds |
| **Duplicated Code** | The same logic in more than one place, including code that copies an existing helper | Extract the shared logic into one function, or call the existing one |
| **Feature Envy** | A function that uses another module's data more than its own | Move the function, or the part that envies, to the module that owns the data |
| **Data Clumps** | The same group of values passed or stored together in several places | Introduce one type or object for the group and pass that |
| **Primitive Obsession** | Strings, numbers, or booleans standing in for a domain concept (money, a status, an id) | Replace the primitive with a small type for the concept |
| **Repeated Switches** | The same `switch` or `if` chain on the same value in more than one place | Replace the switches with one lookup or polymorphism |
| **Shotgun Surgery** | One logical change that needs small edits across many files | Move the scattered pieces into one module |
| **Divergent Change** | One module that changes for several unrelated reasons | Split the module so each part changes for one reason |
| **Speculative Generality** | Parameters, hooks, abstractions, or options nothing uses yet | Remove the unused generality |
| **Message Chains** | Long chains of calls to reach an object (`a.b().c().d()`) | Hide the chain behind one method on the first object |
| **Middle Man** | A class or function that only delegates to another | Remove it and call the delegate directly |
| **Refused Bequest** | A subclass that ignores or overrides most of what it inherits | Replace the inheritance with composition |
