/// @file graphics/graphics.h

#ifndef GRAPHICS_H_
#define GRAPHICS_H_

typedef enum CharType {
	CHAR_ASCII	, /** Normal ASCII Character (0x21 -> 0x7E). */
	CHAR_SPACE	, /** Space Character (0x20). */
	CHAR_NULL	, /** Null Byte (\0). */

	CHAR_GEN_ESC, /** General Escape Characters (\a, \b, \f, 0x7F, etc.). */
	CHAR_TAB	, /** Horizontal & Vertical Tabs (\t, \v). */
	CHAR_LINE	, /** Line Feed Characters (\n, \r). */
	CHAR_ESC	, /** Escape Character (\e). */

	CHAR_ASCII_MAX,

	CHAR_CONTINU, /** UTF-8 Continuation Byte						  (0b10xxxxxx) */
	CHAR_2B_HEAD, /** UTF-8 Header Byte (before 1 continuation byte ) (0b110xxxxx). */
	CHAR_3B_HEAD, /** UTF-8 Header Byte (before 2 continuation bytes) (0b1110xxxx). */
	CHAR_4B_HEAD, /** UTF-8 Header Byte (before 3 continuation bytes) (0b11110xxx). */

	CHAR_INVALID, /** Byte in an Invalid UTF-8 Sequence (�) (0xF8 -> 0xFF). */

	CHAR_TYPE_COUNT
} CharType;

#define CHAR_IS_ASCII(ct) ((bool)(((CharType)ct) < CHAR_ASCII_MAX))

#endif /* !GRAPHICS_H_ */
