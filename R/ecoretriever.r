#' Install datasets via the EcoData Retriever.
#'
#' Data is stored in either CSV files or one of the following database management
#' systems: MySQL, PostgreSQL, SQLite, or Microsoft Access.
#'
#' @param dataset the name of the dataset that you wish to download
#' @param connection what type of database connection should be used. 
#' The options include: mysql, postgres, sqlite, msaccess, or csv'
#' @param db_file the name of the datbase file the dataset should be loaded 
#' into
#' @param conn_file the path to the .conn file that contains the connection
#' configuration options for mysql and postgres databases. This defaults to 
#' mysql.conn or postgres.conn respectively. The connection file is a comma
#' seperated file with four fields: user, password, host, and port. 
#' @param log_dir the location where the retriever log should be stored if
#' the progress is not printed to the console
#' @export
#' @examples
#' install_data('MCDB', 'csv')
install_data = function(dataset, connection, db_file=NULL, conn_file=NULL,
                        log_dir=NULL){
  if (missing(connection)) {
    stop("The argument 'connection' must be set to one of the following options: 'mysql', 'postgres', 'sqlite', 'msaccess', or 'csv'")
  }
  else if (connection == 'mysql' | connection == 'postgres') {
    if (is.null(conn_file)) {
      conn_file = paste('./', connection, '.conn', sep='')
    }
    if (!file.exists(conn_file)) {
      format = '\n    host my_server@myhost.com\n    port 1111\n    user my_user_name\n    password my_pass_word'
      stop(paste("conn_file:", conn_file, "does not exist. To use a",
                  connection, "server create a 'conn_file' with the format:", 
                 format, "\nwhere order of arguments does not matter"))
    }
    conn = data.frame(t(read.table(conn_file, row.names=1)))
    print(paste('Using conn_file:', conn_file,
                'to connect to a', connection, 'server on host:',
                conn$host))
    cmd = paste('retriever install', connection, dataset, '--user', conn$user,
                '--password', conn$password, '--host', conn$host, '--port',
                conn$port)
  }
  else if (connection == 'sqlite' | connection == 'msaccess') {
    if (is.null(db_file))
      cmd = paste('retriever install', connection, dataset)
    else
      cmd = paste('retriever install', connection, dataset, '--file', db_file)
  }
  else if (connection == 'csv')
    cmd = paste('retriever install csv', dataset)
  else
    stop("The argument 'connection' must be set to one of the following options: 'mysql', 'postgres', 'sqlite', 'msaccess', or 'csv'")
  if (!is.null(log_dir)) {
    log_file = file.path(log_dir, paste(dataset, '_download.log', sep=''))
    cmd = paste(cmd, '>', log_file, '2>&1')
  }
  system(cmd)
}



#' Fetch a dataset via the EcoData Retriever
#'
#' Each datafile in a given dataset is downloaded to a temporary directory and
#' then imported as a data.frame as a member of a named list.
#'
#' @param dataset the name of the dataset that you wish to download
#' @param quiet: logical, if true retriever runs in quiet mode
#' @export
#' @examples
#' ## fetch the Mammal Community Database (MCDB)
#' MCDB = fetch('MCDB')
#' class(MCDB)
#' names(MCDB)
#' ## preview the data in the MCDB communities datafile
#' head(MCDB$communities)
fetch = function(dataset, quiet=TRUE){
  start_dir = getwd()
  setwd(tempdir())
  if (quiet)
    system(paste('retriever -q install csv', dataset))
  else
    install_data(dataset, 'csv')
  files = dir('.')
  files = files[grep(dataset, files)]
  out = vector('list', length(files))
  list_names = sub('.csv', '', files)
  list_names = sub(paste(dataset, '_', sep=''), '', list_names)
  names(out) = list_names
  for (i in seq_along(files))
    out[[i]] = read.csv(files[i])
  setwd(start_dir)
  return(out)
}

#' Download datasets via the EcoData Retriever.
#'
#' Directly downloads data files with no processing, allowing downloading of
#' non-tabular data.
#'
#' @param dataset the name of the dataset that you wish to download
#' @param path the path where the data should be downloaded to
#' @param log_dir the location where the retriever log should be stored if
#' the progress is not printed to the console
#' @export
#' @examples
#' download_data('MCDB', './data')
download_data = function(dataset, path='.', log_dir=NULL) {
    cmd = paste('retriever download', dataset, '-p', path)
    if (!is.null(log_dir)) {
        log_file = file.path(log_dir, paste(dataset, '_download.log', sep=''))
        cmd = paste(cmd, '>', log_file, '2>&1')
    }
    system(cmd)
}


#' Update the scripts the EcoData Retriever uses to download datasets 
#'
#' @return returns the log of the Retriever's update
#' @references http://ecodataretriever.org/cli.html
#' @export
#' @examples update_scripts()
update_scripts = function() {
  system('retriever update') 
}

#' Display a list all available dataset scripts
#' @return returns the log of the available datasets for download
#' @export
#' @examples data_ls()
data_ls = function(){
  system('retriever ls') 
}

#' Create a new sample retriever script 
#' 
#' @param filename the name of the script to generate
#' @export
#' @examples new_script('newscript.script')
new_script = function(filename){
  system(paste('retriever new', filename)) 
}

.onAttach <- function(...) {
  packageStartupMessage("\nNew to ecoretriever? Examples at https://github.com/ropensci/ecoretriever/ \ncitation(package='ecoretriever') for the citation for this package \nUse suppressPackageStartupMessages() to suppress these startup messages in the future")
}
