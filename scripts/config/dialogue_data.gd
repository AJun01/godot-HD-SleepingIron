class_name DialogueData
extends Resource
## Data contract for one dialogue beat: ordered lines plus an optional speaker.
## DialogueService is the only consumer; a future full dialogue system replaces
## that consumer while keeping this shape (design.md "DialogueData as the swap
## contract"). Content lives here, never in scenes or the service.

## Speaker name rendered above the line; empty hides the speaker label.
@export var speaker: String = ""

## Ordered lines, advanced one per `advance` press by DialogueService.
@export var lines: Array[String] = []
