#define data_t int
#define OP +

typedef struct {
	size_t len;
	data_t *data;
} vec;

int vec_length(vec *v)
{
	return v->len;
}

int get_vec_element(vec *v, size_t idx, data_t* val)
{
	if (idx >= v->len) {
		return -1; // Index out of bounds
	}
	*val = v->data[idx];
	return 0; // Success
}

void combine1(vec_ptr v, data_t *dest){
	long int i;
	*dest = IDENT;
	for(i = 0; i<vec_length(v); i++){
		data_t val;
		get_vec_element(v, i, &val);
		*dest = dest OP val;
	}
}