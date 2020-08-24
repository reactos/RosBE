/*
 * PROJECT:     RosBE - ReactOS Build Environment for Windows.
 * LICENSE:     GNU General Public License v2. (see LICENSE.txt)
 * PURPOSE:     Manages named shortcuts to ReactOS source directories.
 * COPYRIGHT:   Copyright 2020 Peter Ward <dralnix@gmail.com>
 *                             Daniel Reimer <reimer.daniel@freenet.de>
 *                             Colin Finck <mail@colinfinck.de>
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#if defined(WIN32)
#   include <direct.h>
#   include <io.h>

#   define paccess(path, mode)      _access(path, mode)
#   define pchdir(path)             _chdir(path)
#   define pgetcwd(buffer, maxlen)  _getcwd(buffer, maxlen)
#   define pmkdir(path)             _mkdir(path)
#   define pstricmp(str1, str2)     _stricmp(str1, str2)
#else
#   include <sys/stat.h>
#   include <unistd.h>

#   define paccess(path, mode)      access(path, mode)
#   define pchdir(path)             chdir(path)
#   define pgetcwd(buffer, maxlen)  getcwd(buffer, maxlen)
#   define pmkdir(path)             mkdir(path, S_IRWXU | S_IRGRP | S_IWGRP | S_IROTH | S_IWOTH)         // chmod rights: 0755
#   define pstricmp(str1, str2)     strcasecmp(str1, str2)
#endif



#define LINE_MAX   1024
#define READWRITE  6                   // R_OK | W_OK for access(), these constants don't exist in MSVC

typedef struct _SHORTCUT
{
    char* name;
    char* path;
    struct _SHORTCUT *next;
} SHORTCUT, *PSHORTCUT;


char* programname;
char rosbeappdata[248];
char shortcutfile[260];
int hasshortcuts = 0;

PSHORTCUT addshortcut(PSHORTCUT ptr, char* name, char* path);
void checkfile(void);
int checkname(PSHORTCUT head, char* name);
int checkpath(char* path); // Alters path by fully expanding it.
void defaultshortcut(char* name);
PSHORTCUT deleteshortcut(PSHORTCUT ptr, PSHORTCUT *head);
void editshortcut(PSHORTCUT ptr, char* name, char* path);
void freeshortcuts(PSHORTCUT ptr);
PSHORTCUT previousshortcut(PSHORTCUT current, PSHORTCUT head);
PSHORTCUT readshortcuts(void);
int writeshortcuts(PSHORTCUT head);

int main(int argc, char* argv[])
{
    PSHORTCUT shortcuts = NULL, current = NULL;
    char name[260], path[260];
    int removed = 0;
    programname = argv[0];

#if defined(WIN32)
    strncpy(rosbeappdata, getenv("APPDATA"), 241);
    strcat(rosbeappdata, "\\RosBE");
    strcpy(shortcutfile, rosbeappdata);
    strcat(shortcutfile, "\\srclist.txt");
#else
    strncpy(rosbeappdata, getenv("HOME"), 244);
    strcat(rosbeappdata, "/.RosBE");
    strcpy(shortcutfile, rosbeappdata);
    strcat(shortcutfile, "/srclist");
#endif

    checkfile();

    if (argc > 4)
    {
        fprintf(stderr, "%s: Error too many parameters specified.\n", programname);
        return -1;
    }
    if (argc == 1)
    {
        defaultshortcut(NULL);
    }
    else if ((!strcmp(argv[1], "/?")) ||
             (!pstricmp(argv[1], "-h")) ||
             (!pstricmp(argv[1], "--help")))
    {
        printf("Usage: %s [OPTIONS] [SHORTCUT] [PATH]\n", programname);
        printf("Manages named shortcuts to ReactOS source directories. scut started\n");
        printf("with the name of a shortcut sets this shortcut active.\n\n");
        printf("The following details the options:\n\n");
        printf("   list    - Lists all shortcuts and their paths.\n");
        printf("   add     - Adds a shortcut.\n");
        printf("             (Optional: SHORTCUT PATH as the second and third parameters)\n");
        printf("   rem     - Removes a shortcut.\n");
        printf("             (Optional: SHORTCUT as the second parameter)\n");
        printf("   edit    - Edits a shortcut.\n");
        printf("             (Optional: SHORTCUT PATH as the second and third parameters)\n");
        printf("   def     - Sets the default shortcut which is enabled on\n");
        printf("             every start of RosBE. 'Default' is the source\n");
        printf("             directory as you know it from previous versions.\n\n");
        return 0;
    }
    else if (!pstricmp(argv[1], "list"))
    {
        shortcuts = readshortcuts();
        current = shortcuts;

        if (hasshortcuts)
        {
            printf("All available shortcuts:\n\n");
            while(current)
            {
                if (!pstricmp(current->name, "Default"))
                {
                    current = current->next;
                    continue;
                }
                printf("Shortcut Name: %s\n", current->name);
                printf("      -> Path: %s\n", current->path);
                current = current->next;
            }
        }
        else
        {
            printf("No shortcuts found, use 'scut add' to create one.\n");
        }
        freeshortcuts(shortcuts);
    }
    else if (!pstricmp(argv[1], "add"))
    {
        shortcuts = readshortcuts();
        current = shortcuts;

        if (argc >= 3)
        {
            strcpy(name, argv[2]);
        }
        else
        {
            do
            {
                printf("Please enter a name for the shortcut: ");
                fflush(stdin);

                if(!fgets(name, 260, stdin))
                {
                    freeshortcuts(shortcuts);
                    return -1;
                }
            } while(strlen(name) <= 1);

            strcpy(name, strtok(name, "\n"));
        }
        if (!checkname(shortcuts, name))
        {
            fprintf(stderr, "%s: Shortcut '%s' already exists.\n", programname, name);
        }
        else
        {
            if (argc == 4)
            {
                strcpy(path, argv[3]);
            }
            else
            {
                do
                {
                    printf("Please enter the path for the shortcut: ");
                    fflush(stdin);

                    if(!fgets(path, 260, stdin))
                    {
                        freeshortcuts(shortcuts);
                        return -1;
                    }
                } while(strlen(path) <= 1);

                strcpy(path, strtok(path, "\n"));
            }
            if (!checkpath(path))
            {
                fprintf(stderr, "%s: Directory '%s' doesn't exist.\n", programname, path);
            }
            else
            {
                shortcuts = addshortcut(shortcuts, name, path);
                writeshortcuts(shortcuts);
            }
        }
        freeshortcuts(shortcuts);
    }
    else if (!pstricmp(argv[1], "rem"))
    {
        shortcuts = readshortcuts();
        current = shortcuts;

        if (argc >= 3)
        {
            strcpy(name, argv[2]);
        }
        else
        {
            do
            {
                printf("Please enter the name of the shortcut to remove: ");
                fflush(stdin);

                if(!fgets(name, 260, stdin))
                {
                    freeshortcuts(shortcuts);
                    return -1;
                }
            } while(strlen(name) <= 1);

            strcpy(name, strtok(name, "\n"));
        }
        if (!pstricmp(name, "Default"))
        {
            fprintf(stderr, "%s: Unable to remove default shortcut.\n", programname);
        }
        else
        {
            while(current)
            {
                if (!pstricmp(current->name, name))
                {
                    current = deleteshortcut(current, &shortcuts);
                    removed = 1;
                    break;
                }
                current = current->next;
            }
            if (removed)
            {
                writeshortcuts(shortcuts);
                printf("Removed shortcut: %s\n", name);
            }
            else
            {
                printf("Unable to find shortcut: %s\n", name);
            }
        }
        freeshortcuts(shortcuts);
    }
    else if (!pstricmp(argv[1], "edit"))
    {
        shortcuts = readshortcuts();
        current = shortcuts;

        if (argc >= 3)
        {
            strcpy(name, argv[2]);
        }
        else
        {
            do
            {
                printf("Please enter the name of the shortcut to edit: ");
                fflush(stdin);

                if(!fgets(name, 260, stdin))
                {
                    freeshortcuts(shortcuts);
                    return -1;
                }
            } while(strlen(name) <= 1);

            strcpy(name, strtok(name, "\n"));
        }
        if (!pstricmp(name, "Default") || checkname(shortcuts, name))
        {
            fprintf(stderr, "%s: Shortcut '%s' doesn't exist.\n", programname, name);
        }
        else
        {
            while(current)
            {
                if (!pstricmp(current->name, name))
                {
                    if (argc == 4)
                    {
                        strcpy(path, argv[3]);
                    }
                    else
                    {
                        do
                        {
                            printf("Please enter a new path for the shortcut: ");
                            fflush(stdin);

                            if(!fgets(path, 260, stdin))
                            {
                                freeshortcuts(shortcuts);
                                return -1;
                            }
                        } while(strlen(path) <= 1);

                        strcpy(path, strtok(path, "\n"));
                    }
                    if (!checkpath(path))
                    {
                        fprintf(stderr, "%s: Directory '%s' doesn't exist.\n", programname, path);
                        break;
                    }
                    else
                    {
                        editshortcut(current, name, path);
                        writeshortcuts(shortcuts);
                        printf("Edited shortcut: %s\n", name);
                        break;
                    }
                }
                current = current->next;
            }
        }
        freeshortcuts(shortcuts);
    }
    else if (!pstricmp(argv[1], "def"))
    {
        shortcuts = readshortcuts();
        current = shortcuts;

        if (argc >= 3)
        {
            strcpy(name, argv[2]);
        }
        else
        {
            do
            {
                printf("Please enter the the name of the shortcut to set as default: ");
                fflush(stdin);

                if(!fgets(name, 260, stdin))
                {
                    freeshortcuts(shortcuts);
                    return -1;
                }
            } while(strlen(name) <= 1);

            strcpy(name, strtok(name, "\n"));
        }
        if (!pstricmp(name, "Default") || checkname(shortcuts, name))
        {
            fprintf(stderr, "%s: Shortcut '%s' doesn't exist.\n", programname, name);
            freeshortcuts(shortcuts);
        }
        else
        {
            freeshortcuts(shortcuts);
            defaultshortcut(name);
        }
    }
    else
    {
        if (argc > 2)
        {
            fprintf(stderr, "%s: Error too many parameters specified.\n", programname);
            return -1;
        }
        shortcuts = readshortcuts();
        current = shortcuts;

        strcpy(name, argv[1]);
        if (!pstricmp(name, "Default") || checkname(shortcuts, name))
        {
            fprintf(stderr, "%s: Shortcut '%s' doesn't exist.\n", programname, name);
        }
        else
        {
            while(current)
            {
                if (!pstricmp(current->name, name))
                {
                    printf("%s\n", current->path);
                    break;
                }
                current = current->next;
            }
        }
        freeshortcuts(shortcuts);
    }

    return 0;
}

PSHORTCUT addshortcut(PSHORTCUT ptr, char* name, char* path)
{
    if (!ptr)
    {
        ptr = (PSHORTCUT)malloc(sizeof(SHORTCUT));
        ptr->name = (char*)malloc(strlen(name) + 1);
        strcpy(ptr->name, name);
        ptr->path = (char*)malloc(strlen(path) + 1);
        strcpy(ptr->path, path);
        ptr->next = NULL;
    }
    else
    {
        ptr->next = addshortcut(ptr->next, name, path);
    }

    return ptr;
}

void checkfile(void)
{
    FILE *fp;

    fp = fopen(shortcutfile, "r");
    if (!fp)
    {
        if(paccess(rosbeappdata, READWRITE) == -1)
        {
            // Directory does not exist, create it
            if(pmkdir(rosbeappdata) == -1)
            {
                fprintf(stderr, "%s: Error creating the directory for the RosBE files.\n", programname);
            }
        }

        fp = fopen(shortcutfile, "w");
        if (!fp)
        {
            fprintf(stderr, "%s: Error creating file.\n", programname);
        }
        else
        {
            fprintf(fp, "Default,Default\n");
            if (fclose(fp))
            {
                fprintf(stderr, "%s: Error closing file.\n", programname);
            }
        }
    }
    else
    {
        if (fclose(fp))
        {
            fprintf(stderr, "%s: Error closing file.\n", programname);
        }
    }
}

int checkname(PSHORTCUT head, char* name)
{
    PSHORTCUT current = head;

    while(current)
    {
        if (!pstricmp(current->name, name))
        {
            return 0;
        }
        current = current->next;
    }

    return 1;
}

int checkpath(char* path)
{
    char currentdir[260];
    pgetcwd(currentdir, 260);
    if (!pchdir(path))
    {
        pgetcwd(path, 260);
        pchdir(currentdir);
        return 1;
    }

    return 0;
}

void defaultshortcut(char* name)
{
    PSHORTCUT shortcuts = NULL, current = NULL;
    char path[260];

    shortcuts = readshortcuts();
    current = shortcuts;

    if (!name)
    {
        while(current)
        {
            if (!pstricmp(current->name, "Default"))
            {
                printf("%s\n", current->path);
                break;
            }
            current = current->next;
        }
    }
    else
    {
        while(current)
        {
            if (!pstricmp(current->name, name))
            {
                strcpy(path, current->path);
                current = shortcuts;
                while(current)
                {
                    if (!pstricmp(current->name, "Default"))
                    {
                        editshortcut(current, "Default", path);
                        writeshortcuts(shortcuts);
                        printf("Default shortcut set to: %s\n", path);
                        break;
                    }
                    current = current->next;
                }
                break;
            }
            current = current->next;
        }
    }

    freeshortcuts(shortcuts);
}

PSHORTCUT deleteshortcut(PSHORTCUT current, PSHORTCUT *head)
{
    PSHORTCUT temp = NULL;
    PSHORTCUT previous = NULL;

    if (current)
    {
        temp = current;
        if (current != *head)
        {
            previous = previousshortcut(current, *head);
            current = current->next;
            previous->next = current;
        }
        else
        {
            *head = current->next;
        }
        if (temp->name) free(temp->name);
        if (temp->path) free(temp->path);
        free(temp);
    }

    return current;
}

void editshortcut(PSHORTCUT current, char* name, char* path)
{
    if (current)
    {
        if (name)
        {
            current->name = (char*)realloc(current->name, strlen(name) + 1);
            strcpy(current->name, name);
        }
        if (path)
        {
            current->path = (char*)realloc(current->path, strlen(path) + 1);
            strcpy(current->path, path);
        }
    }
}

void freeshortcuts(PSHORTCUT head)
{
    PSHORTCUT temp = NULL;

    while (head)
    {
        temp = head;
        head = head->next;
        if (temp->name) free(temp->name);
        if (temp->path) free(temp->path);
        free(temp);
    }
}

PSHORTCUT previousshortcut(PSHORTCUT current, PSHORTCUT head)
{
    PSHORTCUT temp = head;

    if(current == head)
    {
        return head;
    }

    while(temp->next != current)
    {
        temp = temp->next;
    }

    return temp;
}

PSHORTCUT readshortcuts(void)
{
    FILE *fp;
    PSHORTCUT head = NULL;
    char strbuff[LINE_MAX];
    char *name = NULL, *path = NULL;

    fp = fopen(shortcutfile, "r");
    if (!fp)
    {
        fprintf(stderr, "%s: Error file doesn't seem to exist.\n", programname);
        return NULL;
    }
    else
    {
        while(!feof(fp))
        {
            fgets(strbuff, LINE_MAX, fp);
            name = strtok(strbuff, ",");
            path = strtok(NULL, "\n");
            if (name && path)
            {
                if (pstricmp(name, "Default") &&
                    !hasshortcuts)
                {
                    hasshortcuts = 1;
                }
                head = addshortcut(head, name, path);
            }
        }
        if (fclose(fp))
        {
            fprintf(stderr, "%s: Error closing file.\n", programname);
            freeshortcuts(head);
            return NULL;
        }
    }

    return head;
}

int writeshortcuts(PSHORTCUT head)
{
    FILE *fp;

    fp = fopen(shortcutfile, "w");
    if (!fp)
    {
        fprintf(stderr, "%s: Error file doesn't seem to exist.\n", programname);
        return -1;
    }
    else
    {
        while(head)
        {
            fprintf(fp, "%s,%s\n", head->name, head->path);
            head = head->next;
        }
        if (fclose(fp))
        {
            fprintf(stderr, "%s: Error closing file.\n", programname);
            return -1;
        }
    }

    return 0;
}
