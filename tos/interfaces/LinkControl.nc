interface LinkControl {
    // only checks locally cached link permissions
    command uint8_t isPermitted(uint8_t src, uint8_t dest);

    // requests validation from th base station if the link status is unknown
    command error_t validateLink(uint8_t src, uint8_t dest);

    // signals that link validation is complete
    event void validationDone( uint8_t src, uint8_t dest, uint8_t status );
}
