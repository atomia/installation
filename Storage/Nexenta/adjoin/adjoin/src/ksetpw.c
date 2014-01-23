/*
 * Copyright 2008 Sun Microsystems, Inc.  All rights reserved.
 * Use is subject to license terms.
 */

#pragma ident	"@(#)ksetpw.c 1.0	08/01/01 SMI"

/*
 * Compile (S10u4):
 * cc ksetpw.c -o ksetpw -R/usr/lib/gss /usr/lib/gss/mech_krb5.so
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <unistd.h>
#include <ctype.h>
#include <errno.h>
#include <kerberosv5/krb5.h>

static void ktadd(krb5_context ctx, krb5_keytab kt, const krb5_principal princ,
			krb5_enctype enctype, krb5_kvno kvno, const char *pw);

static void usage(const char *progname);

int
main(int argc, char **argv)
{
	krb5_context ctx = NULL;
	krb5_error_code code;
	krb5_enctype *enctypes;
	int enctype_count = 0;
	krb5_ccache cc = NULL;
	krb5_keytab kt = NULL;
	krb5_kvno kvno = 1;
	krb5_principal victim;
	char *sprincstr, *vprincstr;
	char c;
	char *ktname, *token, *lasts, *pw, *newpw;
	int result_code, i, len, nflag = 0;
	krb5_data result_code_string, result_string;

	extern krb5_kt_ops krb5_ktf_writable_ops;

	/* Misc init stuff */
	memset(&result_code_string, 0, sizeof (result_code_string));
	memset(&result_string, 0, sizeof (result_string));

	if ((code = krb5_init_context(&ctx)) != 0) {
		(void) fprintf(stderr,
		    "krb5_init_context() failed (err=%d)\n", code);
		return (1);
	}

	if ((code = krb5_kt_register(ctx, &krb5_ktf_writable_ops)) != 0) {
		(void) fprintf(stderr,
		    "krb5_kt_register() failed (err=%d)\n", code);
		return (1);
	}

	while ((c = getopt(argc, argv, "v:c:k:e:n")) != -1) {
		switch (c) {
		case 'n':
			nflag++;
			break;
		case 'k':
			len = snprintf(NULL, 0, "WRFILE:%s", optarg) + 1;
			if ((ktname = malloc(len)) == NULL) {
				fprintf(stderr, "Out of memory\n");
				return (1);
			}
			(void) snprintf(ktname, len, "WRFILE:%s", optarg);
			if ((code = krb5_kt_resolve(ctx, ktname, &kt)) != 0) {
				fprintf(stderr,
				   "Couldn't open/create keytab %s (err=%d)\n",
				    optarg, code);
				return (1);
			}
			break;
		case 'c':
			if (cc != NULL)
				usage(argv[0]);
			if ((code = krb5_cc_resolve(ctx, optarg, &cc)) != 0) {
				fprintf(stderr,
				    "Couldn't open ccache %s (err=%d)\n",
				    optarg, code);
				exit(1);
			}
			break;
		case 'e':
			len = strlen(optarg);
			token = strtok_r(optarg, ",\t,", &lasts);

			if (token == NULL)
				usage(argv[0]);

			do {
				if (enctype_count++ == 0) {
					enctypes = malloc(sizeof (*enctypes));
				} else {
					enctypes = realloc(enctypes,
					    sizeof (*enctypes) * enctype_count);
				}
				code = krb5_string_to_enctype(token,
				    &enctypes[enctype_count - 1]);

				if (code != 0) {
					fprintf(stderr, "Unknown or "
					    "unsupported enctype %s\n",
					    optarg);
					exit(1);
				}
			} while ((token = strtok_r(NULL, ",\t ", &lasts)) !=
			    NULL);
			break;
		case 'v':
			kvno = (krb5_kvno) atoi(optarg);
			break;
		default:
			usage(argv[0]);
			break;
		}
	}

	if (nflag && enctype_count == 0)
		usage(argv[0]);

	if (nflag == 0 && cc == NULL &&
	    (code = krb5_cc_default(ctx, &cc)) != 0) {
		fprintf(stderr,
		    "Could not find a ccache (err=%d)\n", code);
		return (1);
	}

	if (enctype_count > 0 && kt == NULL &&
	    (code = krb5_kt_default(ctx, &kt)) != 0) {
		fprintf(stderr,
		    "Couldn't open default keytab (err=%d)\n", code);
		return (1);
	}

	if (argc != (optind + 1))
		usage(argv[0]);

	vprincstr = argv[optind];
	code = krb5_parse_name(ctx, vprincstr, &victim);
	if (code != 0) {
		(void) fprintf(stderr,
		    "krb5_parse_name(vprinc) failed (err=%d)\n", code);
		return (1);
	}

	if (!isatty(0)) {
		char buf[300];

		if (scanf("%s", &buf) != 1) {
			fprintf(stderr, "Couldn't read new password\n");
			return (1);
		}

		newpw = strdup(buf);
	} else {
		if ((newpw = getpassphrase("Enter new password: ")) == NULL) {
			fprintf(stderr, "Couldn't read new password\n");
			return (1);
		}
		newpw = strdup(newpw);
	}

	if (nflag == 0) {
		code = krb5_set_password_using_ccache(ctx, cc, newpw, victim,
			&result_code, &result_code_string, &result_string);
		if (code != 0) {
			(void) fprintf(stderr, "krb5_set_password() failed\n");
			return (1);
		}
		krb5_cc_close(ctx, cc);

		(void) printf("Result: %.*s (%d) %.*s\n",
		    result_code == 0 ? strlen("success") : result_code_string.length,
		    result_code == 0 ? "success" : result_code_string.data,
		    result_code,
		    result_string.length, result_string.data);
	}

	for (i = 0; i < enctype_count; i++) {
		ktadd(ctx, kt, victim, enctypes[i], kvno, newpw);
	}

	if (kt != NULL)
		krb5_kt_close(ctx, kt);

	return (0);
}


static
void
ktadd(krb5_context ctx, krb5_keytab kt, const krb5_principal princ,
	krb5_enctype enctype, krb5_kvno kvno, const char *pw)
{
	krb5_keytab_entry *entry;
	krb5_timestamp now;
	krb5_data password, salt;
	krb5_keyblock key;
	krb5_error_code code;
	char buf[100];

	if ((code = krb5_enctype_to_string(enctype, buf, sizeof(buf)))) {
		fprintf(stderr, "Enctype %d has no name!\n", enctype);
		return;
	}
	if ((entry = (krb5_keytab_entry *) malloc(sizeof(*entry))) == NULL) {
		fprintf(stderr, "Out of memory\n");
		return;
	}

	memset((char *) entry, 0, sizeof(*entry));

	password.length = strlen(pw);
	password.data = (char *)pw;

	if ((code = krb5_principal2salt(ctx, princ, &salt)) != 0) {
		fprintf(stderr, "Could not compute salt for %s\n", enctype);
		return;
	}

	code = krb5_c_string_to_key(ctx, enctype, &password, &salt, &key);

	if (code != 0) {
		fprintf(stderr, "Could not compute salt for %s\n", enctype);
		krb5_xfree(salt.data);
		return;
	}

	memcpy(&entry->key, &key, sizeof(krb5_keyblock));
	entry->vno = kvno;
	entry->principal = princ;

	if (krb5_kt_add_entry(ctx, kt, entry) != 0)
		fprintf(stderr, "Could not add entry to keytab\n");
}

static
void
usage(const char *progname)
{
	fprintf(stderr, "Usage: %s [-c ccache] [-k keytab] "
		"[-e enctype_list] [-n] princ\n", progname);
	fprintf(stderr, "\t-n\tDon't set the principal's password\n");
	fprintf(stderr, "\tenctype_list is a comma or whitespace separated list\n");
	fprintf(stderr, "\tIf -n is used then -k and -e must be used\n");
	exit(1);
}
