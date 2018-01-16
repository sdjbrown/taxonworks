import Vue from 'vue'; 
import VueResource from 'vue-resource';

Vue.use(VueResource);
Vue.http.headers.common['X-CSRF-Token'] = document.querySelector('meta[name="csrf-token"]').getAttribute('content');

const ajaxCall = function(type, url, data = null) {
  return new Promise(function(resolve, reject) {
    Vue.http[type](url, data).then(response => {
      return resolve(response.body);
    }, response => {
      handleError(response.body);
      return reject(response);
    })
  });
}

const handleError = function(json) {
  if (typeof json != 'object') return
  let errors = Object.keys(json);
  let errorMessage = '';

  errors.forEach(function(item) {
    errorMessage += json[item].join('<br>')
  });

  TW.workbench.alert.create(errorMessage, 'error');
}


const GetParse = function(taxon_name) {
  return new Promise(function(resolve, reject) {
    Vue.http.get(`/taxon_names/parse?query_string=${taxon_name}`, {
      before(request) {
        if (Vue.previousRequest) {
          Vue.previousRequest.abort();
        }
        Vue.previousRequest = request;
      }

    }).then(response => {
      return resolve(response.body)
    })
  })
  //return ajaxCall('get', `/taxon_names/parse?query_string=${taxon_name}`);
}

const GetLastCombinations = function() {
  return ajaxCall('get', `/combinations.json`)
}

const CreateCombination = function(combination) {
  return ajaxCall('post', `/combinations`, combination);
}

export {
  GetParse,
  GetLastCombinations,
  CreateCombination
}